package com.example.feedbackapp.polls.service;

import com.example.feedbackapp.common.error.AlreadyVotedException;
import com.example.feedbackapp.common.error.ConflictException;
import com.example.feedbackapp.common.error.ForbiddenException;
import com.example.feedbackapp.common.error.NotFoundException;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.polls.dto.CreatePollRequest;
import com.example.feedbackapp.polls.dto.PollResponse;
import com.example.feedbackapp.polls.dto.PollSummaryResponse;
import com.example.feedbackapp.polls.entity.Ballot;
import com.example.feedbackapp.polls.entity.Poll;
import com.example.feedbackapp.polls.entity.PollParticipation;
import com.example.feedbackapp.polls.entity.PollParticipationId;
import com.example.feedbackapp.polls.repository.BallotRepository;
import com.example.feedbackapp.polls.repository.PollOptionRepository;
import com.example.feedbackapp.polls.repository.PollParticipationRepository;
import com.example.feedbackapp.polls.repository.PollRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class PollService {

    private static final Logger log = LoggerFactory.getLogger(PollService.class);
    private static final String RESULTS_CACHE_KEY = "poll:results:%d";
    private static final Duration RESULTS_CACHE_TTL = Duration.ofSeconds(3);

    private final PollRepository pollRepository;
    private final PollOptionRepository pollOptionRepository;
    private final PollParticipationRepository participationRepository;
    private final BallotRepository ballotRepository;
    private final StringRedisTemplate redis;
    private final ObjectMapper objectMapper;
    private final ApplicationEventPublisher eventPublisher;

    public PollService(PollRepository pollRepository,
                       PollOptionRepository pollOptionRepository,
                       PollParticipationRepository participationRepository,
                       BallotRepository ballotRepository,
                       StringRedisTemplate redis,
                       ObjectMapper objectMapper,
                       ApplicationEventPublisher eventPublisher) {
        this.pollRepository = pollRepository;
        this.pollOptionRepository = pollOptionRepository;
        this.participationRepository = participationRepository;
        this.ballotRepository = ballotRepository;
        this.redis = redis;
        this.objectMapper = objectMapper;
        this.eventPublisher = eventPublisher;
    }

    @Transactional
    public PollResponse createPoll(CreatePollRequest request, GatewayUser admin) {
        requireAdmin(admin);
        if (!request.endTime().isAfter(request.startTime())) {
            throw new ConflictException("Poll end time must be after start time");
        }
        if (request.options().size() < 2) {
            throw new ConflictException("A poll needs at least two options");
        }
        if (request.options().stream().map(String::trim).distinct().count() != request.options().size()) {
            throw new ConflictException("Poll options must be distinct");
        }

        Poll poll = new Poll();
        poll.setTitle(request.title().trim());
        poll.setDescription(request.description());
        poll.setStartTime(request.startTime());
        poll.setEndTime(request.endTime());
        poll.setAnonymous(request.isAnonymous());
        poll.setCreatedBy(admin.id());
        request.options().forEach(text -> poll.addOption(text.trim()));

        Poll saved = pollRepository.save(poll);
        log.info("Poll {} created by admin {}", saved.getId(), admin.id());
        return toDetailResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<PollSummaryResponse> listPolls(String status) {
        LocalDateTime now = LocalDateTime.now();
        List<Poll> polls = switch (status == null ? "active" : status.toLowerCase()) {
            case "scheduled" -> pollRepository.findAll().stream()
                    .filter(p -> "SCHEDULED".equals(p.status(now))).toList();
            case "closed" -> pollRepository.findClosedPolls(now);
            default -> pollRepository.findActivePolls(now);
        };
        return polls.stream().map(this::toSummaryResponse).toList();
    }

    @Transactional(readOnly = true)
    public PollResponse getPoll(Long pollId) {
        return toDetailResponse(getPollOrThrow(pollId));
    }

    /**
     * Results with the caller's participation flag. The cached payload is
     * user-neutral; hasVoted is overlaid per request after cache retrieval.
     */
    @Transactional(readOnly = true)
    public PollResponse getPollForUser(Long pollId, GatewayUser user) {
        PollResponse response = getResults(pollId);
        return user == null ? response : response.withHasVoted(hasVoted(pollId, user.id()));
    }

    private boolean hasVoted(Long pollId, Long userId) {
        return participationRepository.existsById(new PollParticipationId(pollId, userId));
    }

    /** One-person-one-vote: enforced by the composite PK on poll_participation. */
    @Transactional
    public PollResponse castVote(Long pollId, GatewayUser user, Long optionId) {
        Poll poll = getPollOrThrow(pollId);
        LocalDateTime now = LocalDateTime.now();
        if (!"ACTIVE".equals(poll.status(now))) {
            throw new ConflictException("Poll is not open for voting");
        }
        if (poll.getOptions().stream().noneMatch(o -> o.getId().equals(optionId))) {
            throw new NotFoundException("Option does not belong to this poll");
        }

        try {
            participationRepository.save(new PollParticipation(new PollParticipationId(pollId, user.id())));
            participationRepository.flush(); // surface the PK violation here, inside our transaction
        } catch (DataIntegrityViolationException e) {
            throw new AlreadyVotedException("You have already voted in this poll");
        }

        ballotRepository.save(new Ballot(pollId, optionId));
        pollOptionRepository.incrementVotes(optionId);
        redis.delete(RESULTS_CACHE_KEY.formatted(pollId));
        log.info("User {} voted in poll {}", user.id(), pollId);
        // Broadcast to WebSocket subscribers once the transaction commits.
        eventPublisher.publishEvent(new VoteBroadcastListener.VoteCommittedEvent(pollId));

        return getResults(pollId).withHasVoted(true);
    }

    /** Short-TTL read-through Redis cache in front of the vote counts. */
    @Transactional(readOnly = true)
    public PollResponse getResults(Long pollId) {
        Poll poll = getPollOrThrow(pollId);
        String key = RESULTS_CACHE_KEY.formatted(pollId);
        String cached = redis.opsForValue().get(key);
        if (cached != null) {
            try {
                return objectMapper.readValue(cached, PollResponse.class);
            } catch (Exception e) {
                redis.delete(key); // corrupt cache — recompute
            }
        }
        PollResponse response = toDetailResponse(poll);
        try {
            redis.opsForValue().set(key, objectMapper.writeValueAsString(response), RESULTS_CACHE_TTL);
        } catch (Exception e) {
            log.warn("Failed to cache results for poll {}", pollId, e);
        }
        return response;
    }

    @Transactional
    public PollResponse closePoll(Long pollId, GatewayUser admin) {
        requireAdmin(admin);
        Poll poll = getPollOrThrow(pollId);
        if (!"CLOSED".equals(poll.status(LocalDateTime.now()))) {
            poll.setEndTime(LocalDateTime.now());
        }
        redis.delete(RESULTS_CACHE_KEY.formatted(pollId));
        return toDetailResponse(poll);
    }

    /** Aggregate participation stats for the admin dashboard. */
    @Transactional(readOnly = true)
    public com.example.feedbackapp.polls.dto.PollAnalyticsSummary analyticsSummary() {
        List<Poll> all = pollRepository.findAll();
        LocalDateTime now = LocalDateTime.now();
        long active = all.stream().filter(p -> "ACTIVE".equals(p.status(now))).count();
        long totalVotes = all.stream()
                .flatMap(p -> p.getOptions().stream())
                .mapToLong(o -> o.getVotesCount())
                .sum();
        var top = all.stream()
                .max(java.util.Comparator.comparingLong(p -> p.getOptions().stream()
                        .mapToLong(o -> o.getVotesCount()).sum()))
                .filter(p -> p.getOptions().stream().mapToLong(o -> o.getVotesCount()).sum() > 0)
                .map(p -> new com.example.feedbackapp.polls.dto.PollAnalyticsSummary.TopPoll(
                        p.getId(), p.getTitle(),
                        p.getOptions().stream().mapToLong(o -> o.getVotesCount()).sum()))
                .orElse(null);
        double avg = all.isEmpty() ? 0.0 : Math.round(totalVotes * 10.0 / all.size()) / 10.0;
        return new com.example.feedbackapp.polls.dto.PollAnalyticsSummary(
                all.size(), active, totalVotes, avg, top);
    }

    private Poll getPollOrThrow(Long pollId) {
        return pollRepository.findById(pollId)
                .orElseThrow(() -> new NotFoundException("Poll %d not found".formatted(pollId)));
    }

    private void requireAdmin(GatewayUser user) {
        if (user == null || !user.isAdmin()) {
            throw new ForbiddenException("Only admins can perform this action");
        }
    }

    private PollSummaryResponse toSummaryResponse(Poll poll) {
        long total = poll.getOptions().stream().mapToLong(o -> o.getVotesCount()).sum();
        return new PollSummaryResponse(
                poll.getId(), poll.getTitle(), poll.getDescription(),
                poll.status(LocalDateTime.now()),
                poll.getStartTime().toString(), poll.getEndTime().toString(),
                total, poll.getOptions().size());
    }

    private PollResponse toDetailResponse(Poll poll) {
        long total = poll.getOptions().stream().mapToLong(o -> o.getVotesCount()).sum();
        List<PollResponse.OptionResult> results = poll.getOptions().stream()
                .map(o -> new PollResponse.OptionResult(
                        o.getId(), o.getOptionText(), o.getVotesCount(),
                        total == 0 ? 0.0 : Math.round(o.getVotesCount() * 1000.0 / total) / 10.0))
                .toList();
        return new PollResponse(
                poll.getId(), poll.getTitle(), poll.getDescription(),
                poll.status(LocalDateTime.now()), poll.isAnonymous(),
                poll.getStartTime().toString(), poll.getEndTime().toString(),
                total, false, results);
    }
}
