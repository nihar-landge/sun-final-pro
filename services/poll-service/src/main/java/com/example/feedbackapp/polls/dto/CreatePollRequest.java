package com.example.feedbackapp.polls.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.List;

public record CreatePollRequest(
        @NotBlank @Size(max = 200)
        String title,

        @Size(max = 5000)
        String description,

        @NotNull
        LocalDateTime startTime,

        @NotNull
        LocalDateTime endTime,

        boolean isAnonymous,

        @NotEmpty
        List<@NotBlank @Size(max = 200) String> options) {
}
