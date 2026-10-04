package com.example.feedbackapp.feedback.repository;

import com.example.feedbackapp.feedback.entity.FeedbackUpvote;
import com.example.feedbackapp.feedback.entity.FeedbackUpvoteId;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FeedbackUpvoteRepository extends JpaRepository<FeedbackUpvote, FeedbackUpvoteId> {
}
