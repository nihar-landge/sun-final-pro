package com.example.feedbackapp.feedback.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class FeedbackUpvoteId implements Serializable {

    @Column(name = "feedback_id")
    private Long feedbackId;

    @Column(name = "user_id")
    private Long userId;

    public FeedbackUpvoteId() {
    }

    public FeedbackUpvoteId(Long feedbackId, Long userId) {
        this.feedbackId = feedbackId;
        this.userId = userId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof FeedbackUpvoteId that)) return false;
        return Objects.equals(feedbackId, that.feedbackId) && Objects.equals(userId, that.userId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(feedbackId, userId);
    }

    public Long getFeedbackId() {
        return feedbackId;
    }
}
