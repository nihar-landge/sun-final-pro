package com.example.feedbackapp.polls.repository;

import com.example.feedbackapp.polls.entity.Ballot;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BallotRepository extends JpaRepository<Ballot, Long> {
}
