package com.example.feedbackapp.common.event;

import java.time.Instant;

/**
 * Domain event published to RabbitMQ (topic exchange `feedbackapp.events`).
 * Sent as JSON; consumed by notification-service.
 *
 * type:          "feedback.created" | "feedback.status.changed"
 * oldStatus:     only for status.changed
 * newStatus:     only for status.changed
 */
public record FeedbackEvent(
        String type,
        Long feedbackId,
        Long userId,
        String title,
        String category,
        String oldStatus,
        String newStatus,
        Instant occurredAt) {

    public static final String CREATED = "feedback.created";
    public static final String STATUS_CHANGED = "feedback.status.changed";
}
