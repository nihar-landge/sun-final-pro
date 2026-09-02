package com.example.feedbackapp.feedback.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import org.locationtech.jts.geom.Point;

import java.time.LocalDateTime;

@Entity
@Table(name = "feedback")
public class Feedback {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(columnDefinition = "text")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 50)
    private FeedbackCategory category;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private FeedbackStatus status = FeedbackStatus.OPEN;

    /** PostGIS geography point (SRID 4326); nullable — feedback need not be geo-tagged. */
    @Column(columnDefinition = "geography(Point,4326)")
    private Point location;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "sentiment_score")
    private Float sentimentScore;

    @Column(name = "sentiment_label", length = 10)
    private String sentimentLabel;

    @Column(nullable = false)
    private int upvotes = 0;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        this.updatedAt = now;
        if (this.status == null) {
            this.status = FeedbackStatus.OPEN;
        }
    }

    @PreUpdate
    void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public FeedbackCategory getCategory() {
        return category;
    }

    public void setCategory(FeedbackCategory category) {
        this.category = category;
    }

    public FeedbackStatus getStatus() {
        return status;
    }

    public void setStatus(FeedbackStatus status) {
        this.status = status;
    }

    public Point getLocation() {
        return location;
    }

    public void setLocation(Point location) {
        this.location = location;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public Float getSentimentScore() {
        return sentimentScore;
    }

    public void setSentimentScore(Float sentimentScore) {
        this.sentimentScore = sentimentScore;
    }

    public String getSentimentLabel() {
        return sentimentLabel;
    }

    public void setSentimentLabel(String sentimentLabel) {
        this.sentimentLabel = sentimentLabel;
    }

    public int getUpvotes() {
        return upvotes;
    }

    public void setUpvotes(int upvotes) {
        this.upvotes = upvotes;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
}
