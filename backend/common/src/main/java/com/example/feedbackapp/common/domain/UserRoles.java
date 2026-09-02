package com.example.feedbackapp.common.domain;

import java.util.Set;

/**
 * Role names used across services, in JWT claims and in the users table.
 */
public final class UserRoles {

    public static final String CITIZEN = "CITIZEN";
    public static final String MODERATOR = "MODERATOR";
    public static final String ADMIN = "ADMIN";

    public static final Set<String> ALL = Set.of(CITIZEN, MODERATOR, ADMIN);

    private UserRoles() {
    }
}
