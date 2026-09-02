package com.example.feedbackapp.polls.dto;

public record PollSummaryResponse(
        Long id,
        String title,
        String description,
        String status,
        String startTime,
        String endTime,
        long totalVotes,
        int optionCount) {
}
