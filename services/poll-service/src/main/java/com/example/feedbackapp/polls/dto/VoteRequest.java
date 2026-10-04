package com.example.feedbackapp.polls.dto;

import jakarta.validation.constraints.NotNull;

public record VoteRequest(@NotNull Long optionId) {
}
