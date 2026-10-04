package com.example.feedbackapp.feedback.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/** Audit trail for admin status transitions. */
@Entity
@Table(name = "feedback_status_history")
public class FeedbackStatusHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "feedback_id", nullable = false)
    private Long feedbackId;

    @Enumerated(EnumType.STRING)
    @Column(name = "old_status", length = 20)
    private FeedbackStatus oldStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "new_status", nullable = false, length = 20)
    private FeedbackStatus newStatus;

    @Column(name = "changed_by")
    private Long changedBy;

    @Column(name = "changed_at", nullable = false)
    private LocalDateTime changedAt;

    public FeedbackStatusHistory() {
    }

    public FeedbackStatusHistory(Long feedbackId, FeedbackStatus oldStatus,
                                 FeedbackStatus newStatus, Long changedBy) {
        this.feedbackId = feedbackId;
        this.oldStatus = oldStatus;
        this.newStatus = newStatus;
        this.changedBy = changedBy;
        this.changedAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public Long getFeedbackId() {
        return feedbackId;
    }

    public FeedbackStatus getOldStatus() {
        return oldStatus;
    }

    public FeedbackStatus getNewStatus() {
        return newStatus;
    }

    public Long getChangedBy() {
        return changedBy;
    }

    public LocalDateTime getChangedAt() {
        return changedAt;
    }
}
