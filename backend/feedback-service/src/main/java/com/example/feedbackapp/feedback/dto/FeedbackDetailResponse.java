package com.example.feedbackapp.feedback.dto;

import java.util.List;

public record FeedbackDetailResponse(
        Long id,
        String title,
        String description,
        String category,
        String status,
        int upvotes,
        Double latitude,
        Double longitude,
        Long userId,
        String createdAt,
        List<CommentResponse> comments,
        List<StatusChangeResponse> history) {

    public record CommentResponse(Long id, Long userId, String text, String createdAt) {
    }

    public record StatusChangeResponse(String oldStatus, String newStatus, Long changedBy, String changedAt) {
    }
}
