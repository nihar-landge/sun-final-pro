package com.example.feedbackapp.feedback.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/** One photo attached to a report. Bytes live in MinIO; we store the key. */
@Entity
@Table(name = "feedback_images")
public class FeedbackImage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "feedback_id", nullable = false)
    private Long feedbackId;

    @Column(name = "image_url", nullable = false, length = 255)
    private String objectKey;

    @Column(name = "uploaded_at", nullable = false)
    private LocalDateTime uploadedAt;

    public FeedbackImage() {
    }

    public FeedbackImage(Long feedbackId, String objectKey) {
        this.feedbackId = feedbackId;
        this.objectKey = objectKey;
        this.uploadedAt = LocalDateTime.now();
    }

    @PrePersist
    void onCreate() {
        if (this.uploadedAt == null) {
            this.uploadedAt = LocalDateTime.now();
        }
    }

    public Long getId() {
        return id;
    }

    public Long getFeedbackId() {
        return feedbackId;
    }

    public String getObjectKey() {
        return objectKey;
    }

    public LocalDateTime getUploadedAt() {
        return uploadedAt;
    }
}
