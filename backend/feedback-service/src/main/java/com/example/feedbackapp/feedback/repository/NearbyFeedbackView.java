package com.example.feedbackapp.feedback.repository;

import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;

/**
 * Projection for the PostGIS near-me query. distanceMeters comes from
 * ST_Distance, not a table column.
 */
public interface NearbyFeedbackView {

    Long getId();

    String getTitle();

    String getCategory();

    String getStatus();

    Integer getUpvotes();

    LocalDateTime getCreatedAt();

    double getDistanceMeters();

    Double getLatitude();

    Double getLongitude();
}
