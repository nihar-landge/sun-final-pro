package com.example.feedbackapp.auth.dto;

import java.time.LocalDateTime;

public record UserResponse(Long id, String phone, String name, String role, LocalDateTime createdAt) {
}
