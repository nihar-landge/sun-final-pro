package com.example.feedbackapp.notifications.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/**
 * One citizen-facing inbox row, owned by notification-service and stored in
 * notificationdb. Created when another service reports a domain event
 * (e.g. "report status changed") over the internal API.
 */
@Entity
@Table(name = "notifications")
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** Event type, e.g. REPORT_STATUS. */
    @Column(nullable = false, length = 50)
    private String type;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 500)
    private String body;

    /** Reference to the domain object (e.g. the report id) for deep links. */
    @Column(name = "ref_id")
    private Long refId;

    @Column(name = "read_at")
    private LocalDateTime readAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    protected Notification() {
    }

    public Notification(Long userId, String type, String title, String body, Long refId) {
        this.userId = userId;
        this.type = type;
        this.title = title;
        this.body = body;
        this.refId = refId;
    }

    public boolean isUnread() {
        return readAt == null;
    }

    public void markRead() {
        this.readAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public Long getUserId() {
        return userId;
    }

    public String getType() {
        return type;
    }

    public String getTitle() {
        return title;
    }

    public String getBody() {
        return body;
    }

    public Long getRefId() {
        return refId;
    }

    public LocalDateTime getReadAt() {
        return readAt;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
