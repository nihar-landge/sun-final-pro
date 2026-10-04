package com.example.feedbackapp.feedback.dto;

import com.example.feedbackapp.feedback.repository.NearbyFeedbackView;

import java.util.List;

public record NearbyFeedbackResponse(
        Long id,
        String title,
        String category,
        String status,
        int upvotes,
        String createdAt,
        double distanceMeters,
        Double latitude,
        Double longitude) {

    public static NearbyFeedbackResponse from(NearbyFeedbackView view) {
        return new NearbyFeedbackResponse(
                view.getId(), view.getTitle(), view.getCategory(), view.getStatus(),
                view.getUpvotes() == null ? 0 : view.getUpvotes(),
                view.getCreatedAt() == null ? null : view.getCreatedAt().toString(),
                Math.round(view.getDistanceMeters()),
                view.getLatitude(),
                view.getLongitude());
    }

    public static List<NearbyFeedbackResponse> from(List<NearbyFeedbackView> views) {
        return views.stream().map(NearbyFeedbackResponse::from).toList();
    }
}
