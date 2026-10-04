package com.example.feedbackapp.notifications.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.time.Duration;

/**
 * Calls the Express email service. Email delivery is a supporting
 * concern: any failure (connection refused, timeout, SMTP error) is
 * logged and swallowed — it can never fail the notification itself.
 */
@Component
public class EmailClient {

    private static final Logger log = LoggerFactory.getLogger(EmailClient.class);

    private final RestClient restClient;
    private final String serviceKey;

    public EmailClient(@Value("${email.url:http://localhost:8090}") String baseUrl,
                       @Value("${email-service.service-key:dev-service-key}") String serviceKey) {
        this.serviceKey = serviceKey;
        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .requestFactory(new org.springframework.http.client.SimpleClientHttpRequestFactory() {{
                    setConnectTimeout(Duration.ofSeconds(3));
                    setReadTimeout(Duration.ofSeconds(3));
                }})
                .build();
    }

    public void sendReportStatusEmail(ReportStatusEmail email) {
        try {
            restClient.post()
                    .uri("/api/email/report-status")
                    .contentType(MediaType.APPLICATION_JSON)
                    .header("X-Service-Key", serviceKey)
                    .body(email)
                    .retrieve()
                    .toBodilessEntity();
            log.info("Report-status email dispatched for report {}", email.reportId());
        } catch (Exception e) {
            // Supporting service down or SMTP failed — the app carries on.
            log.warn("Email dispatch failed for report {} — continuing without email: {}",
                    email.reportId(), e.getMessage());
        }
    }

    /** Payload mirroring the Express contract (email-service /api/email/report-status). */
    public record ReportStatusEmail(String email, String name, Long reportId,
                                    String reportTitle, String oldStatus, String newStatus) {
    }
}
