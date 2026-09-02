package com.example.feedbackapp.polls.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class PollParticipationId implements Serializable {

    @Column(name = "poll_id")
    private Long pollId;

    @Column(name = "user_id")
    private Long userId;

    public PollParticipationId() {
    }

    public PollParticipationId(Long pollId, Long userId) {
        this.pollId = pollId;
        this.userId = userId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof PollParticipationId that)) return false;
        return Objects.equals(pollId, that.pollId) && Objects.equals(userId, that.userId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(pollId, userId);
    }

    public Long getPollId() {
        return pollId;
    }

    public Long getUserId() {
        return userId;
    }
}
