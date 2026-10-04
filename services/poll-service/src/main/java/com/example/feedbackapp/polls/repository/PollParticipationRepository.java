package com.example.feedbackapp.polls.repository;

import com.example.feedbackapp.polls.entity.PollParticipation;
import com.example.feedbackapp.polls.entity.PollParticipationId;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PollParticipationRepository extends JpaRepository<PollParticipation, PollParticipationId> {
}
