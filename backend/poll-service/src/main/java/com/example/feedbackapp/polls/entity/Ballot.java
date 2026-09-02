package com.example.feedbackapp.polls.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/**
 * Anonymous ballot: no user_id, so published results can never be traced
 * back to a voter. Eligibility is proven by poll_participation instead.
 */
@Entity
@Table(name = "ballots")
public class Ballot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "poll_id", nullable = false)
    private Long pollId;

    @Column(name = "option_id", nullable = false)
    private Long optionId;

    @Column(name = "voted_at", nullable = false)
    private LocalDateTime votedAt;

    public Ballot() {
    }

    public Ballot(Long pollId, Long optionId) {
        this.pollId = pollId;
        this.optionId = optionId;
        this.votedAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public Long getPollId() {
        return pollId;
    }

    public Long getOptionId() {
        return optionId;
    }
}
