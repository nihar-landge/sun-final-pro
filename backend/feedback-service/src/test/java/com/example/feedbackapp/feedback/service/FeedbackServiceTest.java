package com.example.feedbackapp.feedback.service;

import com.example.feedbackapp.common.error.ConflictException;
import com.example.feedbackapp.common.error.ForbiddenException;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.feedback.dto.FeedbackSummaryResponse;
import com.example.feedbackapp.feedback.dto.StatusUpdateRequest;
import com.example.feedbackapp.feedback.dto.SubmitFeedbackRequest;
import com.example.feedbackapp.feedback.entity.Comment;
import com.example.feedbackapp.feedback.entity.Feedback;
import com.example.feedbackapp.feedback.entity.FeedbackCategory;
import com.example.feedbackapp.feedback.entity.FeedbackStatus;
import com.example.feedbackapp.feedback.repository.CommentRepository;
import com.example.feedbackapp.feedback.repository.FeedbackRepository;
import com.example.feedbackapp.feedback.repository.FeedbackStatusHistoryRepository;
import com.example.feedbackapp.feedback.repository.FeedbackUpvoteRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FeedbackServiceTest {

    @Mock
    private FeedbackRepository feedbackRepository;
    @Mock
    private FeedbackUpvoteRepository upvoteRepository;
    @Mock
    private CommentRepository commentRepository;
    @Mock
    private FeedbackStatusHistoryRepository historyRepository;
    @Mock
    private org.springframework.amqp.rabbit.core.RabbitTemplate rabbitTemplate;

    private FeedbackService feedbackService;

    private static final GatewayUser CITIZEN = new GatewayUser(2L, "CITIZEN", "Nihar");
    private static final GatewayUser ADMIN = new GatewayUser(1L, "ADMIN", "Admin");

    @BeforeEach
    void setUp() {
        feedbackService = new FeedbackService(feedbackRepository, upvoteRepository,
                commentRepository, historyRepository, rabbitTemplate,
                new com.fasterxml.jackson.databind.ObjectMapper());
    }

    private Feedback feedback(long id) {
        Feedback feedback = new Feedback();
        ReflectionTestUtils.setField(feedback, "id", id);
        feedback.setTitle("Broken streetlight");
        feedback.setCategory(FeedbackCategory.ELECTRICITY);
        feedback.setStatus(FeedbackStatus.OPEN);
        feedback.setUpvotes(4);
        ReflectionTestUtils.setField(feedback, "createdAt", java.time.LocalDateTime.now());
        ReflectionTestUtils.setField(feedback, "updatedAt", java.time.LocalDateTime.now());
        return feedback;
    }

    @Test
    @DisplayName("submit stores a geo-tagged OPEN feedback item")
    void submitStoresGeoTaggedFeedback() {
        when(feedbackRepository.save(any(Feedback.class))).thenAnswer(inv -> {
            Feedback f = inv.getArgument(0);
            ReflectionTestUtils.setField(f, "id", 7L);
            // @PrePersist does not run under a mocked save
            ReflectionTestUtils.setField(f, "createdAt", java.time.LocalDateTime.now());
            ReflectionTestUtils.setField(f, "updatedAt", java.time.LocalDateTime.now());
            return f;
        });

        FeedbackSummaryResponse response = feedbackService.submit(
                new SubmitFeedbackRequest("Broken streetlight", "Dark for a week",
                        FeedbackCategory.ELECTRICITY, 18.5204, 73.8567), CITIZEN);

        assertThat(response.id()).isEqualTo(7L);
        assertThat(response.status()).isEqualTo("OPEN");
        assertThat(response.latitude()).isEqualTo(18.5204);
        assertThat(response.longitude()).isEqualTo(73.8567);
    }

    @Test
    @DisplayName("duplicate upvote is rejected as conflict")
    void duplicateUpvoteRejected() {
        doThrow(new DataIntegrityViolationException("dup"))
                .when(upvoteRepository).save(any());

        assertThatThrownBy(() -> feedbackService.upvote(7L, CITIZEN))
                .isInstanceOf(ConflictException.class);
        verify(upvoteRepository).save(any());
    }

    @Test
    @DisplayName("allowed status transition writes an audit row")
    void allowedTransitionWritesHistory() {
        when(feedbackRepository.findById(7L)).thenReturn(Optional.of(feedback(7L)));
        when(commentRepository.findByFeedbackIdOrderByCreatedAtAsc(7L)).thenReturn(java.util.List.of());
        when(historyRepository.findByFeedbackIdOrderByChangedAtAsc(7L)).thenReturn(java.util.List.of());

        var detail = feedbackService.transitionStatus(
                7L, new StatusUpdateRequest(FeedbackStatus.IN_REVIEW), ADMIN);

        assertThat(detail.status()).isEqualTo("IN_REVIEW");
        verify(historyRepository).save(any());
    }

    private static final GatewayUser MODERATOR = new GatewayUser(3L, "MODERATOR", "Mod");

    @Test
    @DisplayName("moderators can change feedback status (content management)")
    void moderatorCanTransition() {
        when(feedbackRepository.findById(7L)).thenReturn(Optional.of(feedback(7L)));
        when(commentRepository.findByFeedbackIdOrderByCreatedAtAsc(7L)).thenReturn(java.util.List.of());
        when(historyRepository.findByFeedbackIdOrderByChangedAtAsc(7L)).thenReturn(java.util.List.of());

        var detail = feedbackService.transitionStatus(
                7L, new StatusUpdateRequest(FeedbackStatus.IN_REVIEW), MODERATOR);

        assertThat(detail.status()).isEqualTo("IN_REVIEW");
        verify(historyRepository).save(any());
    }

    @Test
    @DisplayName("adminUpdate applies only supplied fields")
    void adminUpdatePartial() {
        when(feedbackRepository.findById(7L)).thenReturn(Optional.of(feedback(7L)));
        when(commentRepository.findByFeedbackIdOrderByCreatedAtAsc(7L)).thenReturn(java.util.List.of());
        when(historyRepository.findByFeedbackIdOrderByChangedAtAsc(7L)).thenReturn(java.util.List.of());

        var request = new com.example.feedbackapp.feedback.dto.AdminUpdateFeedbackRequest(
                null, "Amit Sharma", "Inspection scheduled", null, null);

        var detail = feedbackService.adminUpdate(7L, request, ADMIN);

        assertThat(detail.status()).isEqualTo("OPEN");
        assertThat(detail.assignedTo()).isEqualTo("Amit Sharma");
        assertThat(detail.publicNote()).isEqualTo("Inspection scheduled");
        assertThat(detail.internalNote()).isNull();
        assertThat(detail.hidden()).isFalse();
    }

    @Test
    @DisplayName("non-admins cannot change feedback status")
    void illegalTransitionRejected() {
        // The admin check fires before the repository is touched.
        assertThatThrownBy(() -> feedbackService.transitionStatus(
                7L, new StatusUpdateRequest(FeedbackStatus.IN_REVIEW), CITIZEN))
                .isInstanceOf(ForbiddenException.class);
        org.mockito.Mockito.verifyNoInteractions(feedbackRepository);
    }

    @Test
    @DisplayName("comments require an existing feedback item")
    void commentOnMissingFeedback() {
        when(feedbackRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatCode(() -> feedbackService.addComment(
                        99L, new com.example.feedbackapp.feedback.dto.CommentRequest("hi"), CITIZEN))
                .isInstanceOf(com.example.feedbackapp.common.error.NotFoundException.class);
        verify(commentRepository, org.mockito.Mockito.never()).save(any(Comment.class));
    }
}
