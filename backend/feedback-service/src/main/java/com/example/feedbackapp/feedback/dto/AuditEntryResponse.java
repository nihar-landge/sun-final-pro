package com.example.feedbackapp.feedback.dto;

/** One audited status transition, joined with the report title. */
public record AuditEntryResponse(
        Long id,
        Long feedbackId,
        String reportTitle,
        String category,
        String oldStatus,
        String newStatus,
        Long changedBy,
        String changedAt) {
}
