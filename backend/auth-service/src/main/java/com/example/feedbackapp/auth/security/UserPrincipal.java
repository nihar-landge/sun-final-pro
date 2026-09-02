package com.example.feedbackapp.auth.security;

import com.example.feedbackapp.common.domain.UserRoles;

/**
 * Authenticated caller details resolved from the JWT claims.
 */
public record UserPrincipal(Long id, String phone, String name, String role) {

    public UserPrincipal {
        if (role == null) {
            role = UserRoles.CITIZEN;
        }
    }
}
