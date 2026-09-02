package com.example.feedbackapp.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record SendOtpRequest(
        @NotBlank
        @Pattern(regexp = "\\d{10,15}", message = "phone must be 10-15 digits")
        String phone) {
}
