package com.example.feedbackapp.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record VerifyOtpRequest(
        @NotBlank
        @Pattern(regexp = "\\d{10,15}", message = "phone must be 10-15 digits")
        String phone,

        @NotBlank
        @Pattern(regexp = "\\d{6}", message = "code must be 6 digits")
        String code,

        @Size(max = 100, message = "name must be at most 100 characters")
        String name) {
}
