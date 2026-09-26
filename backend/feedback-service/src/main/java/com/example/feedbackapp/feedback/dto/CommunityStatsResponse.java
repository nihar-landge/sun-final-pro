package com.example.feedbackapp.feedback.dto;

/** Public community-impact numbers for the citizen Home screen. */
public record CommunityStatsResponse(
        long totalReports,
        long resolvedReports,
        int resolutionRatePercent,
        long totalUpvotes) {
}
