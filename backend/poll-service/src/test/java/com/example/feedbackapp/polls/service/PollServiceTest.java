package com.example.feedbackapp.polls.service;

import com.example.feedbackapp.common.error.AlreadyVotedException;
import com.example.feedbackapp.common.error.ConflictException;
import com.example.feedbackapp.common.error.ForbiddenException;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.polls.dto.CreatePollRequest;
import com.example.feedbackapp.polls.dto.PollResponse;
import com.example.feedbackapp.polls.entity.Ballot;
import com.example.feedbackapp.polls.entity.Poll;
import com.example.feedbackapp.polls.entity.PollParticipation;
import com.example.feedbackapp.polls.entity.PollParticipationId;
import com.example.feedbackapp.polls.repository.BallotRepository;
import com.example.feedbackapp.polls.repository.PollOptionRepository;
import com.example.feedbackapp.polls.repository.PollParticipationRepository;
import com.example.feedbackapp.polls.repository.PollRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PollServiceTest {

    @Mock
    private PollRepository pollRepository;
    @Mock
    private PollOptionRepository pollOptionRepository;
    @Mock
    private PollParticipationRepository participationRepository;
    @Mock
    private BallotRepository ballotRepository;
    @Mock
    private StringRedisTemplate redis;
    @Mock
    private ValueOperations<String, String> valueOps;

    private PollService pollService;

    private static final GatewayUser ADMIN = new GatewayUser(1L, "ADMIN", "Admin", "user1@test.in");
    private static final GatewayUser CITIZEN = new GatewayUser(2L, "CITIZEN", "Nihar", "user2@test.in");

    @BeforeEach
    void setUp() {
        pollService = new PollService(pollRepository, pollOptionRepository, participationRepository,
                ballotRepository, redis, new ObjectMapper(),
                org.mockito.Mockito.mock(org.springframework.context.ApplicationEventPublisher.class));
        lenient().when(redis.opsForValue()).thenReturn(valueOps);
    }

    private Poll activePoll() {
        Poll poll = new Poll();
        ReflectionTestUtils.setField(poll, "id", 10L);
        poll.setTitle("New park?");
        poll.setStartTime(LocalDateTime.now().minusHours(1));
        poll.setEndTime(LocalDateTime.now().plusHours(5));
        poll.setCreatedBy(ADMIN.id());
        com.example.feedbackapp.polls.entity.PollOption yes =
                new com.example.feedbackapp.polls.entity.PollOption();
        ReflectionTestUtils.setField(yes, "id", 100L);
        yes.setOptionText("Yes");
        yes.setVotesCount(3);
        com.example.feedbackapp.polls.entity.PollOption no =
                new com.example.feedbackapp.polls.entity.PollOption();
        ReflectionTestUtils.setField(no, "id", 101L);
        no.setOptionText("No");
        no.setVotesCount(1);
        poll.getOptions().add(yes);
        poll.getOptions().add(no);
        return poll;
    }

    @Test
    @DisplayName("castVote records participation + ballot and increments the counter")
    void castVoteSuccess() {
        Poll poll = activePoll();
        when(pollRepository.findById(10L)).thenReturn(Optional.of(poll));

        PollResponse response = pollService.castVote(10L, CITIZEN, 101L);

        verify(participationRepository).save(any(PollParticipation.class));
        verify(ballotRepository).save(any(Ballot.class));
        verify(pollOptionRepository).incrementVotes(101L);
        // The increment is a DB-side update (mocked here), so in-memory counts stay 3+1:
        assertThat(response.totalVotes()).isEqualTo(4);
        assertThat(response.results().stream()
                .filter(r -> r.optionId().equals(101L)).findFirst().orElseThrow().votes())
                .isEqualTo(1);
    }

    @Test
    @DisplayName("castVote rejects a second vote by the same user (PK violation)")
    void castVoteAlreadyVoted() {
        when(pollRepository.findById(10L)).thenReturn(Optional.of(activePoll()));
        org.mockito.Mockito.doThrow(new DataIntegrityViolationException("dup"))
                .when(participationRepository).save(any(PollParticipation.class));

        assertThatThrownBy(() -> pollService.castVote(10L, CITIZEN, 100L))
                .isInstanceOf(AlreadyVotedException.class);
        verify(ballotRepository, never()).save(any(Ballot.class));
        verify(pollOptionRepository, never()).incrementVotes(100L);
    }

    @Test
    @DisplayName("castVote rejects votes on a closed poll")
    void castVotePollClosed() {
        Poll poll = activePoll();
        poll.setEndTime(LocalDateTime.now().minusMinutes(1)); // now closed
        when(pollRepository.findById(10L)).thenReturn(Optional.of(poll));

        assertThatThrownBy(() -> pollService.castVote(10L, CITIZEN, 100L))
                .isInstanceOf(ConflictException.class);
        verify(participationRepository, never()).save(any());
    }

    @Test
    @DisplayName("only admins can create polls")
    void createPollRequiresAdmin() {
        CreatePollRequest request = new CreatePollRequest(
                "T", null, LocalDateTime.now(), LocalDateTime.now().plusDays(1), false,
                List.of("A", "B"));

        assertThatThrownBy(() -> pollService.createPoll(request, CITIZEN))
                .isInstanceOf(ForbiddenException.class);
        verify(pollRepository, never()).save(any());
    }

    @Test
    @DisplayName("createPoll validates the time window and option count")
    void createPollValidation() {
        LocalDateTime now = LocalDateTime.now();
        CreatePollRequest badWindow = new CreatePollRequest(
                "T", null, now, now, false, List.of("A", "B"));
        CreatePollRequest oneOption = new CreatePollRequest(
                "T", null, now, now.plusDays(1), false, List.of("A"));

        assertThatThrownBy(() -> pollService.createPoll(badWindow, ADMIN))
                .isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> pollService.createPoll(oneOption, ADMIN))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    @DisplayName("results read through the Redis cache when present")
    void resultsFromCache() throws Exception {
        Poll poll = activePoll();
        when(pollRepository.findById(10L)).thenReturn(Optional.of(poll));
        PollResponse fresh = new ObjectMapper().readValue(
                new ObjectMapper().writeValueAsString(new com.example.feedbackapp.polls.dto.PollResponse(
                        10L, "CACHED", null, "ACTIVE", false,
                        poll.getStartTime().toString(), poll.getEndTime().toString(), 99, false, List.of())),
                PollResponse.class);
        when(valueOps.get(eq("poll:results:10"))).thenReturn(
                new ObjectMapper().writeValueAsString(fresh));

        PollResponse response = pollService.getResults(10L);

        assertThat(response.title()).isEqualTo("CACHED");
        assertThat(response.totalVotes()).isEqualTo(99);
    }

    @Test
    @DisplayName("hasVoted reflects the caller's participation, overlaid on the cached payload")
    void hasVotedOverlaidPerUser() {
        Poll poll = activePoll();
        when(pollRepository.findById(10L)).thenReturn(Optional.of(poll));
        when(participationRepository.existsById(
                new com.example.feedbackapp.polls.entity.PollParticipationId(10L, 2L))).thenReturn(true);

        PollResponse response = pollService.getPollForUser(10L, CITIZEN);

        assertThat(response.hasVoted()).isTrue();
    }

    @Test
    @DisplayName("closePoll ends an active poll immediately")
    void closePollEndsActivePoll() {
        Poll poll = activePoll();
        when(pollRepository.findById(10L)).thenReturn(Optional.of(poll));

        PollResponse response = pollService.closePoll(10L, ADMIN);

        assertThat(response.status()).isEqualTo("CLOSED");
        assertThat(poll.getEndTime()).isBefore(LocalDateTime.now().plusSeconds(1));
        verify(redis).delete("poll:results:10");
    }

    @Test
    @DisplayName("closePoll rejects a SCHEDULED poll instead of violating the time window")
    void closePollRejectsScheduledPoll() {
        Poll poll = activePoll();
        LocalDateTime originalEnd = LocalDateTime.now().plusDays(3);
        poll.setStartTime(LocalDateTime.now().plusDays(2));
        poll.setEndTime(originalEnd);
        when(pollRepository.findById(10L)).thenReturn(Optional.of(poll));

        assertThatThrownBy(() -> pollService.closePoll(10L, ADMIN))
                .isInstanceOf(ConflictException.class);
        assertThat(poll.getEndTime()).isEqualTo(originalEnd);
        verify(redis, never()).delete(anyString());
    }

    @Test
    @DisplayName("listPolls supports the all/scheduled/closed/active filters")
    void listPollsFilters() {
        Poll poll = activePoll();
        when(pollRepository.findAll()).thenReturn(List.of(poll));
        when(pollRepository.findActivePolls(any(LocalDateTime.class))).thenReturn(List.of(poll));
        when(pollRepository.findClosedPolls(any(LocalDateTime.class))).thenReturn(List.of());

        assertThat(pollService.listPolls("all")).hasSize(1);
        assertThat(pollService.listPolls(null)).hasSize(1);
        assertThat(pollService.listPolls("scheduled")).isEmpty();
        assertThat(pollService.listPolls("closed")).isEmpty();

        verify(pollRepository).findActivePolls(any(LocalDateTime.class));
        verify(pollRepository).findClosedPolls(any(LocalDateTime.class));
    }
}
