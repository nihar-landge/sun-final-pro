package com.example.feedbackapp.feedback.dto;

import com.example.feedbackapp.feedback.entity.FeedbackStatus;
import jakarta.validation.constraints.Size;

/**
 * Admin/moderator operations on a report. Every field is optional; only the
 * supplied ones are applied (partial update semantics).
 */
public record AdminUpdateFeedbackRequest(
        FeedbackStatus newStatus,
        @Size(max = 100) String assignedTo,
        @Size(max = 5000) String publicNote,
        @Size(max = 5000) String internalNote,
        Boolean hidden) {
}
