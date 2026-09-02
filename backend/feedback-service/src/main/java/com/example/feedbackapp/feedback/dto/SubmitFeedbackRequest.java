package com.example.feedbackapp.feedback.dto;

import com.example.feedbackapp.feedback.entity.FeedbackCategory;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record SubmitFeedbackRequest(
        @NotBlank @Size(max = 200)
        String title,

        @NotBlank @Size(max = 5000)
        String description,

        @NotNull
        FeedbackCategory category,

        Double latitude,
        Double longitude) {
}
