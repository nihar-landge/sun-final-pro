package com.example.feedbackapp.auth.dto;

/**
 * The token pair was collapsed to a single 24h access token: no refresh
 * rotation, no server-side token store.
 */
public record TokenResponse(String accessToken, String tokenType, long expiresIn, UserResponse user) {

    public static TokenResponse bearer(String accessToken, long expiresIn, UserResponse user) {
        return new TokenResponse(accessToken, "Bearer", expiresIn, user);
    }
}
