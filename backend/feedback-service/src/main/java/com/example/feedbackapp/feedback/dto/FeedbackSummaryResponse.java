package com.example.feedbackapp.feedback.dto;

public record FeedbackSummaryResponse(
        Long id,
        String title,
        String description,
        String category,
        String status,
        int upvotes,
        Double latitude,
        Double longitude,
        String createdAt) {
}
