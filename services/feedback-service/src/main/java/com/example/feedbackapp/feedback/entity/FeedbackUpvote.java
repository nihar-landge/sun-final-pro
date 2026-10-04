package com.example.feedbackapp.feedback.entity;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import org.springframework.data.domain.Persistable;

import java.time.LocalDateTime;

/**
 * One upvote per user per feedback item, enforced by the composite primary key.
 * Persistable/isNew for the same reason as poll_participation: without it,
 * Spring Data merges (UPDATE) instead of inserting, bypassing the PK.
 */
@Entity
@Table(name = "feedback_upvotes")
public class FeedbackUpvote implements Persistable<FeedbackUpvoteId> {

    @EmbeddedId
    private FeedbackUpvoteId id;

    @Column(name = "voted_at", nullable = false)
    private LocalDateTime votedAt;

    public FeedbackUpvote() {
    }

    public FeedbackUpvote(FeedbackUpvoteId id) {
        this.id = id;
        this.votedAt = LocalDateTime.now();
    }

    @Override
    public FeedbackUpvoteId getId() {
        return id;
    }

    @Override
    public boolean isNew() {
        return true; // upvotes are insert-only, never updated
    }
}
