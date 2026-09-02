package com.example.feedbackapp.polls.entity;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import org.springframework.data.domain.Persistable;

import java.time.LocalDateTime;

/**
 * The one-person-one-vote rule: the composite primary key (poll_id, user_id)
 * makes a second vote by the same user physically impossible.
 *
 * Implements Persistable with isNew()==true because Spring Data would
 * otherwise treat a populated @EmbeddedId as an existing row and issue
 * UPDATE (merge) instead of INSERT — silently bypassing the PK constraint.
 */
@Entity
@Table(name = "poll_participation")
public class PollParticipation implements Persistable<PollParticipationId> {

    @EmbeddedId
    private PollParticipationId id;

    @Column(name = "voted_at", nullable = false)
    private LocalDateTime votedAt;

    public PollParticipation() {
    }

    public PollParticipation(PollParticipationId id) {
        this.id = id;
        this.votedAt = LocalDateTime.now();
    }

    @Override
    public PollParticipationId getId() {
        return id;
    }

    @Override
    public boolean isNew() {
        return true; // participations are insert-only, never updated
    }

    public LocalDateTime getVotedAt() {
        return votedAt;
    }
}
