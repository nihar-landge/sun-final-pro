package com.example.feedbackapp.feedback.repository;

import com.example.feedbackapp.feedback.entity.FeedbackImage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FeedbackImageRepository extends JpaRepository<FeedbackImage, Long> {

    List<FeedbackImage> findByFeedbackIdOrderByIdAsc(Long feedbackId);

    long countByFeedbackId(Long feedbackId);
}
