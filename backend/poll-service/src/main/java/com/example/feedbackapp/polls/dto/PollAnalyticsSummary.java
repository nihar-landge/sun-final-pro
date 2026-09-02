package com.example.feedbackapp.polls.dto;

public record PollAnalyticsSummary(
        long totalPolls,
        long activePolls,
        long totalVotes,
        double avgVotesPerPoll,
        TopPoll topPoll) {

    public record TopPoll(Long id, String title, long totalVotes) {
    }
}
