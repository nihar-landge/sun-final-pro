package com.example.feedbackapp.polls.dto;

import java.util.List;

public record PollResponse(
        Long id,
        String title,
        String description,
        String status,
        boolean anonymous,
        String startTime,
        String endTime,
        long totalVotes,
        boolean hasVoted,
        List<OptionResult> results) {

    public record OptionResult(Long optionId, String text, int votes, double percentage) {
    }

    /** Per-user view: the cached/shared payload is neutral, hasVoted is overlaid per caller. */
    public PollResponse withHasVoted(boolean voted) {
        return new PollResponse(id, title, description, status, anonymous, startTime, endTime,
                totalVotes, voted, results);
    }
}
