package com.example.feedbackapp.feedback.repository;

import com.example.feedbackapp.feedback.entity.Comment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CommentRepository extends JpaRepository<Comment, Long> {

    List<Comment> findByFeedbackIdOrderByCreatedAtAsc(Long feedbackId);
}
