package com.example.feedbackapp.feedback.dto;

import jakarta.validation.constraints.NotBlank;

public record ImagePresignRequest(
        @NotBlank String contentType) {
}
