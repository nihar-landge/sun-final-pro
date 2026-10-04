package com.example.feedbackapp.polls.repository;

import com.example.feedbackapp.polls.entity.Poll;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface PollRepository extends JpaRepository<Poll, Long> {

    @Query("SELECT p FROM Poll p WHERE p.startTime <= :now AND p.endTime > :now ORDER BY p.startTime DESC")
    List<Poll> findActivePolls(@Param("now") LocalDateTime now);

    @Query("SELECT p FROM Poll p WHERE p.endTime <= :now ORDER BY p.endTime DESC")
    List<Poll> findClosedPolls(@Param("now") LocalDateTime now);
}
