package com.example.feedbackapp.feedback.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.web.client.RestClient;

import java.time.Duration;

/**
 * Forwards committed report-status changes to the notification service
 * (which owns the citizen inbox and the email dispatch).
 *
 * The listener runs strictly AFTER the feedback transaction commits, so a
 * notification-service outage can never roll back or fail a status change:
 * the HTTP call is wrapped in try/catch and any error is only logged.
 */
@Component
public class NotificationForwarder {

    private static final Logger log = LoggerFactory.getLogger(NotificationForwarder.class);

    private final RestClient restClient;
    private final String serviceKey;

    public NotificationForwarder(
            @Value("${notification-service.base-url:http://localhost:8084}") String baseUrl,
            @Value("${internal.service-key:dev-service-key}") String serviceKey) {
        this.serviceKey = serviceKey;
        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .requestFactory(new org.springframework.http.client.SimpleClientHttpRequestFactory() {{
                    setConnectTimeout(Duration.ofSeconds(3));
                    setReadTimeout(Duration.ofSeconds(3));
                }})
                .build();
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onStatusChanged(StatusChangedEvent event) {
        try {
            restClient.post()
                    .uri("/internal/notifications")
                    .contentType(MediaType.APPLICATION_JSON)
                    .header("X-Service-Key", serviceKey)
                    .body(new InternalRequest(event.userId(), event.reporterEmail(), event.reporterName(),
                            event.reportId(), event.reportTitle(), event.oldStatus(), event.newStatus()))
                    .retrieve()
                    .toBodilessEntity();
            log.info("Status change of report {} forwarded to notification-service", event.reportId());
        } catch (Exception e) {
            // Notification delivery is supporting, not critical: the report
            // status is already committed and must stay successful.
            log.warn("Could not reach notification-service for report {} — in-app notification "
                    + "and email skipped: {}", event.reportId(), e.getMessage());
        }
    }

    /** Mirrors the internal contract of notification-service (/internal/notifications). */
    record InternalRequest(Long userId, String email, String name, Long reportId,
                           String reportTitle, String oldStatus, String newStatus) {
    }
}
