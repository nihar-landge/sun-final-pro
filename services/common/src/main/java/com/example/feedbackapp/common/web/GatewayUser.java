package com.example.feedbackapp.common.web;

import com.example.feedbackapp.common.domain.UserRoles;

/**
 * Authenticated caller as resolved from the trusted X-User-* headers that
 * the API gateway injects after JWT validation. Services must never accept
 * these headers from outside the gateway (network-boundary trust).
 */
public record GatewayUser(Long id, String role, String name, String email) {

    public boolean isAdmin() {
        return UserRoles.ADMIN.equals(role);
    }
}
