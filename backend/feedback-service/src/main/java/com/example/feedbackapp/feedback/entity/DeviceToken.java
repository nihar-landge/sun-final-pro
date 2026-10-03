package com.example.feedbackapp.feedback.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/** The citizen's FCM device token — one per user (latest wins). */
@Entity
@Table(name = "device_token")
public class DeviceToken {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @Column(nullable = false, columnDefinition = "text")
    private String token;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public DeviceToken() {
    }

    public DeviceToken(Long userId, String token) {
        this.userId = userId;
        this.token = token;
    }

    @PrePersist
    @PreUpdate
    void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public Long getUserId() {
        return userId;
    }

    public String getToken() {
        return token;
    }
}
