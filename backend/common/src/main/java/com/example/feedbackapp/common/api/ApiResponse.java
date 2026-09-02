package com.example.feedbackapp.common.api;

import java.time.Instant;

/**
 * Standard response envelope for every service endpoint.
 *
 * @param success  whether the request succeeded
 * @param data     payload (null on errors)
 * @param message  human-readable message, useful for errors or confirmations
 * @param timestamp response time (UTC)
 */
public record ApiResponse<T>(boolean success, T data, String message, Instant timestamp) {

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, null, Instant.now());
    }

    public static <T> ApiResponse<T> ok(T data, String message) {
        return new ApiResponse<>(true, data, message, Instant.now());
    }

    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(false, null, message, Instant.now());
    }
}
