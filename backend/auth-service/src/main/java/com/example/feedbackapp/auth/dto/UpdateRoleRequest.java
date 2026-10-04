package com.example.feedbackapp.auth.dto;

import com.example.feedbackapp.auth.entity.User;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record UpdateRoleRequest(
        @NotBlank
        @Pattern(regexp = "CITIZEN|ADMIN", message = "role must be CITIZEN or ADMIN")
        String newRole) {

    public static UpdateRoleRequest of(String role) {
        return new UpdateRoleRequest(role);
    }

    public User.Role toRole() {
        return User.Role.valueOf(newRole());
    }
}
