package com.example.feedbackapp.feedback.dto;

import java.util.Map;

public record FeedbackAnalyticsSummary(
        long totalFeedback,
        Map<String, Long> byStatus,
        Map<String, Long> byCategory,
        Double avgResolutionHours,
        long submittedLast7Days) {
}
