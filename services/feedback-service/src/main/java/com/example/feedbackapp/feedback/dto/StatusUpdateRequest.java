package com.example.feedbackapp.feedback.dto;

import com.example.feedbackapp.feedback.entity.FeedbackStatus;
import jakarta.validation.constraints.NotNull;

public record StatusUpdateRequest(@NotNull FeedbackStatus newStatus) {
}
