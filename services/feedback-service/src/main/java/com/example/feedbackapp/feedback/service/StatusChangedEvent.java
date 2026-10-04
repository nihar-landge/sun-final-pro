package com.example.feedbackapp.feedback.service;

/**
 * Published inside the status-update transaction; consumed AFTER COMMIT by
 * {@link NotificationForwarder}. Carries everything the notification
 * service needs, so no extra lookup is required later.
 */
public record StatusChangedEvent(Long userId, String reporterEmail, String reporterName,
                                 Long reportId, String reportTitle,
                                 String oldStatus, String newStatus) {
}
