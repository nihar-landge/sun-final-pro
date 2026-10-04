package com.example.feedbackapp.polls.dto;

import java.util.List;

/**
 * List-card payload. Carries the result preview so cards can render
 * percentage bars without a detail call per poll.
 */
public record PollSummaryResponse(
        Long id,
        String title,
        String description,
        String status,
        String startTime,
        String endTime,
        long totalVotes,
        int optionCount,
        List<PollResponse.OptionResult> results) {
}
