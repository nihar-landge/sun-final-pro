package com.example.feedbackapp.feedback.service;

import com.example.feedbackapp.common.event.FeedbackEvent;
import com.example.feedbackapp.common.error.ConflictException;
import com.example.feedbackapp.common.error.ForbiddenException;
import com.example.feedbackapp.common.error.NotFoundException;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.feedback.dto.CommentRequest;
import com.example.feedbackapp.feedback.dto.FeedbackDetailResponse;
import com.example.feedbackapp.feedback.dto.FeedbackSummaryResponse;
import com.example.feedbackapp.feedback.dto.NearbyFeedbackResponse;
import com.example.feedbackapp.feedback.dto.StatusUpdateRequest;
import com.example.feedbackapp.feedback.dto.SubmitFeedbackRequest;
import com.example.feedbackapp.feedback.entity.Comment;
import com.example.feedbackapp.feedback.entity.Feedback;
import com.example.feedbackapp.feedback.entity.FeedbackCategory;
import com.example.feedbackapp.feedback.entity.FeedbackStatus;
import com.example.feedbackapp.feedback.entity.FeedbackStatusHistory;
import com.example.feedbackapp.feedback.entity.FeedbackUpvote;
import com.example.feedbackapp.feedback.entity.FeedbackUpvoteId;
import com.example.feedbackapp.feedback.repository.CommentRepository;
import com.example.feedbackapp.feedback.repository.FeedbackRepository;
import com.example.feedbackapp.feedback.repository.FeedbackStatusHistoryRepository;
import com.example.feedbackapp.feedback.repository.FeedbackUpvoteRepository;
import jakarta.persistence.criteria.Predicate;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class FeedbackService {

    private static final Logger log = LoggerFactory.getLogger(FeedbackService.class);
    private static final GeometryFactory GEOMETRY = new GeometryFactory(new PrecisionModel(), 4326);

    /** Admin workflow transitions (re-openings included). */
    private static final Map<FeedbackStatus, Set<FeedbackStatus>> ALLOWED_TRANSITIONS = Map.of(
            FeedbackStatus.OPEN, Set.of(FeedbackStatus.IN_REVIEW, FeedbackStatus.RESOLVED),
            FeedbackStatus.IN_REVIEW, Set.of(FeedbackStatus.RESOLVED, FeedbackStatus.OPEN),
            FeedbackStatus.RESOLVED, Set.of(FeedbackStatus.OPEN));

    private final FeedbackRepository feedbackRepository;
    private final FeedbackUpvoteRepository upvoteRepository;
    private final CommentRepository commentRepository;
    private final FeedbackStatusHistoryRepository historyRepository;
    private final RabbitTemplate rabbitTemplate;
    private final com.fasterxml.jackson.databind.ObjectMapper objectMapper;

    public FeedbackService(FeedbackRepository feedbackRepository,
                           FeedbackUpvoteRepository upvoteRepository,
                           CommentRepository commentRepository,
                           FeedbackStatusHistoryRepository historyRepository,
                           RabbitTemplate rabbitTemplate,
                           com.fasterxml.jackson.databind.ObjectMapper objectMapper) {
        this.feedbackRepository = feedbackRepository;
        this.upvoteRepository = upvoteRepository;
        this.commentRepository = commentRepository;
        this.historyRepository = historyRepository;
        this.rabbitTemplate = rabbitTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public FeedbackSummaryResponse submit(SubmitFeedbackRequest request, GatewayUser user) {
        Feedback feedback = new Feedback();
        feedback.setTitle(request.title().trim());
        feedback.setDescription(request.description().trim());
        feedback.setCategory(request.category());
        feedback.setUserId(user.id());
        if (request.latitude() != null && request.longitude() != null) {
            feedback.setLocation(point(request.latitude(), request.longitude()));
        }

        Feedback saved = feedbackRepository.save(feedback);
        log.info("Feedback {} submitted by user {} ({})", saved.getId(), user.id(), request.category());
        publishEvent(new FeedbackEvent(FeedbackEvent.CREATED, saved.getId(), saved.getUserId(),
                saved.getTitle(), saved.getCategory().name(), null, null, java.time.Instant.now()));
        return toSummary(saved);
    }

    @Transactional(readOnly = true)
    public Page<FeedbackSummaryResponse> list(FeedbackCategory category, FeedbackStatus status,
                                              int page, int size, GatewayUser viewer,
                                              boolean includeHidden) {
        boolean staff = viewer != null && (viewer.isAdmin() || "MODERATOR".equals(viewer.role()));
        Specification<Feedback> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (!staff || !includeHidden) {
                predicates.add(cb.isFalse(root.get("hidden")));
            }
            if (category != null) {
                predicates.add(cb.equal(root.get("category"), category));
            }
            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        };
        return feedbackRepository
                .findAll(spec, PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")))
                .map(this::toSummary);
    }

    @Transactional(readOnly = true)
    public List<NearbyFeedbackResponse> nearMe(double lat, double lng, double radiusKm, FeedbackStatus status) {
        return NearbyFeedbackResponse.from(
                feedbackRepository.findNearby(lat, lng, radiusKm * 1000.0,
                        status == null ? null : status.name()));
    }

    @Transactional
    public void upvote(Long feedbackId, GatewayUser user) {
        try {
            upvoteRepository.save(new FeedbackUpvote(new FeedbackUpvoteId(feedbackId, user.id())));
            upvoteRepository.flush();
        } catch (DataIntegrityViolationException e) {
            throw new ConflictException("You have already upvoted this feedback");
        }
        feedbackRepository.incrementUpvotes(feedbackId);
    }

    /** Moderators manage content (status transitions, hiding); admins additionally manage users/polls. */
    private void requireModeratorOrAdmin(GatewayUser user) {
        if (user == null || !(user.isAdmin() || "MODERATOR".equals(user.role()))) {
            throw new ForbiddenException("Only moderators or admins can perform this action");
        }
    }

    @Transactional
    public FeedbackDetailResponse transitionStatus(Long feedbackId, StatusUpdateRequest request, GatewayUser admin) {
        requireModeratorOrAdmin(admin);
        Feedback feedback = getFeedbackOrThrow(feedbackId);
        FeedbackStatus oldStatus = feedback.getStatus();
        if (!ALLOWED_TRANSITIONS.getOrDefault(oldStatus, Set.of()).contains(request.newStatus())) {
            throw new ConflictException(
                    "Transition %s -> %s is not allowed".formatted(oldStatus, request.newStatus()));
        }
        feedback.setStatus(request.newStatus());
        historyRepository.save(new FeedbackStatusHistory(feedbackId, oldStatus, request.newStatus(), admin.id()));
        publishEvent(new FeedbackEvent(FeedbackEvent.STATUS_CHANGED, feedbackId, feedback.getUserId(),
                feedback.getTitle(), feedback.getCategory().name(),
                oldStatus.name(), request.newStatus().name(), java.time.Instant.now()));
        return getDetail(feedbackId, admin);
    }

    /**
     * Partial admin/moderator update: only supplied fields are applied.
     * Status changes go through the same validated, audited transition path.
     */
    @Transactional
    public FeedbackDetailResponse adminUpdate(Long feedbackId,
                                              com.example.feedbackapp.feedback.dto.AdminUpdateFeedbackRequest request,
                                              GatewayUser operator) {
        requireModeratorOrAdmin(operator);
        Feedback feedback = getFeedbackOrThrow(feedbackId);

        if (request.newStatus() != null && request.newStatus() != feedback.getStatus()) {
            FeedbackStatus oldStatus = feedback.getStatus();
            if (!ALLOWED_TRANSITIONS.getOrDefault(oldStatus, Set.of()).contains(request.newStatus())) {
                throw new ConflictException(
                        "Transition %s -> %s is not allowed".formatted(oldStatus, request.newStatus()));
            }
            feedback.setStatus(request.newStatus());
            historyRepository.save(new FeedbackStatusHistory(feedbackId, oldStatus,
                    request.newStatus(), operator.id()));
        }
        if (request.assignedTo() != null) {
            feedback.setAssignedTo(request.assignedTo().isBlank() ? null : request.assignedTo().trim());
        }
        if (request.publicNote() != null) {
            feedback.setPublicNote(request.publicNote().isBlank() ? null : request.publicNote().trim());
        }
        if (request.internalNote() != null) {
            feedback.setInternalNote(request.internalNote().isBlank() ? null : request.internalNote().trim());
        }
        if (request.hidden() != null) {
            feedback.setHidden(request.hidden());
        }
        log.info("Feedback {} updated by {} {} (assigned={}, hidden={})", feedbackId,
                operator.role(), operator.id(), feedback.getAssignedTo(), feedback.isHidden());
        return getDetail(feedbackId, operator);
    }

    /** Full audit trail: every status transition with the report title. */
    @Transactional(readOnly = true)
    public List<com.example.feedbackapp.feedback.dto.AuditEntryResponse> auditTrail(int limit) {
        return historyRepository.findAll(org.springframework.data.domain.PageRequest.of(
                        0, Math.min(Math.max(limit, 1), 500),
                        org.springframework.data.domain.Sort.by(
                                org.springframework.data.domain.Sort.Direction.DESC, "changedAt")))
                .map(h -> {
                    String title = feedbackRepository.findById(h.getFeedbackId())
                            .map(f -> f.getTitle()).orElse("(deleted report)");
                    String category = feedbackRepository.findById(h.getFeedbackId())
                            .map(f -> f.getCategory().name()).orElse(null);
                    return new com.example.feedbackapp.feedback.dto.AuditEntryResponse(
                            h.getId(), h.getFeedbackId(), title, category,
                            h.getOldStatus() == null ? null : h.getOldStatus().name(),
                            h.getNewStatus().name(), h.getChangedBy(), h.getChangedAt().toString());
                })
                .getContent();
    }

    @Transactional
    public FeedbackDetailResponse addComment(Long feedbackId, CommentRequest request, GatewayUser user) {
        getFeedbackOrThrow(feedbackId); // ensure the target exists
        commentRepository.save(new Comment(feedbackId, user.id(), request.text().trim()));
        return getDetail(feedbackId, user);
    }

    @Transactional(readOnly = true)
    public FeedbackDetailResponse getDetail(Long feedbackId, GatewayUser viewer) {
        Feedback feedback = getFeedbackOrThrow(feedbackId);
        if (feedback.isHidden()) {
            boolean staff = viewer != null && (viewer.isAdmin() || "MODERATOR".equals(viewer.role()));
            if (!staff) {
                throw new NotFoundException("Feedback %d not found".formatted(feedbackId));
            }
        }
        List<FeedbackDetailResponse.CommentResponse> comments = commentRepository
                .findByFeedbackIdOrderByCreatedAtAsc(feedbackId).stream()
                .map(c -> new FeedbackDetailResponse.CommentResponse(
                        c.getId(), c.getUserId(), c.getText(), c.getCreatedAt().toString()))
                .toList();
        List<FeedbackDetailResponse.StatusChangeResponse> history = historyRepository
                .findByFeedbackIdOrderByChangedAtAsc(feedbackId).stream()
                .map(h -> new FeedbackDetailResponse.StatusChangeResponse(
                        h.getOldStatus() == null ? null : h.getOldStatus().name(),
                        h.getNewStatus().name(), h.getChangedBy(), h.getChangedAt().toString()))
                .toList();

        return new FeedbackDetailResponse(
                feedback.getId(), feedback.getTitle(), feedback.getDescription(),
                feedback.getCategory().name(), feedback.getStatus().name(), feedback.getUpvotes(),
                latOf(feedback), lngOf(feedback), feedback.getUserId(),
                feedback.getCreatedAt().toString(),
                feedback.getAssignedTo(), feedback.getPublicNote(), feedback.getInternalNote(),
                feedback.isHidden(), comments, history);
    }

    @Transactional(readOnly = true)
    public List<FeedbackSummaryResponse> myReports(GatewayUser user) {
        return feedbackRepository.findByUserIdOrderByIdDesc(user.id()).stream()
                .map(this::toSummary)
                .toList();
    }

    /** Aggregate stats for the admin dashboard. */
    @Transactional(readOnly = true)
    public com.example.feedbackapp.feedback.dto.FeedbackAnalyticsSummary analyticsSummary() {
        Map<String, Long> byStatus = new java.util.LinkedHashMap<>();
        for (FeedbackStatus status : FeedbackStatus.values()) {
            byStatus.put(status.name(), feedbackRepository.count(
                    (root, query, cb) -> cb.equal(root.get("status"), status)));
        }
        Map<String, Long> byCategory = new java.util.LinkedHashMap<>();
        for (FeedbackCategory category : FeedbackCategory.values()) {
            byCategory.put(category.name(), feedbackRepository.count(
                    (root, query, cb) -> cb.equal(root.get("category"), category)));
        }
        Double avgHours = feedbackRepository.avgResolutionHours();
        long last7Days = feedbackRepository.countByCreatedAtAfter(java.time.LocalDateTime.now().minusDays(7));
        return new com.example.feedbackapp.feedback.dto.FeedbackAnalyticsSummary(
                feedbackRepository.count(), byStatus, byCategory,
                avgHours == null ? null : Math.round(avgHours * 10.0) / 10.0, last7Days);
    }

    /** Publishes a domain event; a broker outage must never fail the API call. */
    private void publishEvent(FeedbackEvent event) {
        try {
            rabbitTemplate.convertAndSend(
                    com.example.feedbackapp.feedback.config.RabbitMqConfig.EXCHANGE,
                    event.type(), // routing key, e.g. feedback.created
                    objectMapper.writeValueAsString(event));
            log.debug("Published {} for feedback {}", event.type(), event.feedbackId());
        } catch (Exception e) {
            log.warn("Failed to publish {} for feedback {}: {}", event.type(), event.feedbackId(), e.getMessage());
        }
    }

    private Feedback getFeedbackOrThrow(Long feedbackId) {
        return feedbackRepository.findById(feedbackId)
                .orElseThrow(() -> new NotFoundException("Feedback %d not found".formatted(feedbackId)));
    }

    private Point point(double lat, double lng) {
        Point point = GEOMETRY.createPoint(new Coordinate(lng, lat)); // (x=lng, y=lat)
        point.setSRID(4326);
        return point;
    }

    private Double latOf(Feedback feedback) {
        return feedback.getLocation() == null ? null : feedback.getLocation().getY();
    }

    private Double lngOf(Feedback feedback) {
        return feedback.getLocation() == null ? null : feedback.getLocation().getX();
    }

    private FeedbackSummaryResponse toSummary(Feedback feedback) {
        return new FeedbackSummaryResponse(
                feedback.getId(), feedback.getTitle(), feedback.getDescription(),
                feedback.getCategory().name(), feedback.getStatus().name(), feedback.getUpvotes(),
                latOf(feedback), lngOf(feedback), feedback.getCreatedAt().toString(),
                feedback.getAssignedTo(), feedback.isHidden());
    }
}
