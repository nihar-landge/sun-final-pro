package com.example.feedbackapp.feedback.repository;

import com.example.feedbackapp.feedback.entity.FeedbackStatusHistory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FeedbackStatusHistoryRepository extends JpaRepository<FeedbackStatusHistory, Long> {

    List<FeedbackStatusHistory> findByFeedbackIdOrderByChangedAtAsc(Long feedbackId);
}
