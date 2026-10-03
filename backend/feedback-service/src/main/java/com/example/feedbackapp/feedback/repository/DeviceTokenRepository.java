package com.example.feedbackapp.feedback.repository;

import com.example.feedbackapp.feedback.entity.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {
}
