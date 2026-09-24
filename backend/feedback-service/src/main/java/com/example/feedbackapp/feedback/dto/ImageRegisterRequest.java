package com.example.feedbackapp.feedback.dto;

import jakarta.validation.constraints.NotBlank;

public record ImageRegisterRequest(@NotBlank String objectKey) {
}
