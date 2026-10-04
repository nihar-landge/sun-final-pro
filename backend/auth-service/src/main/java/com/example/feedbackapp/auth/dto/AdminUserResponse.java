package com.example.feedbackapp.auth.dto;

import com.example.feedbackapp.auth.entity.User;

public record AdminUserResponse(Long id, String email, String name, String role, String createdAt) {

    public static AdminUserResponse from(User user) {
        return new AdminUserResponse(user.getId(), user.getEmail(), user.getName(),
                user.getRole().name(),
                user.getCreatedAt() == null ? null : user.getCreatedAt().toString());
    }
}
