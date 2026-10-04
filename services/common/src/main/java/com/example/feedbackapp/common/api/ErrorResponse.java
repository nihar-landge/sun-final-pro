package com.example.feedbackapp.common.api;

import java.time.Instant;
import java.util.Map;

/**
 * Machine-readable error payload returned by every service (also what the
 * gateway forwards when a downstream service is unreachable).
 */
public record ErrorResponse(String code, String message, Map<String, Object> details, Instant timestamp) {

    public static ErrorResponse of(String code, String message) {
        return new ErrorResponse(code, message, Map.of(), Instant.now());
    }

    public static ErrorResponse of(String code, String message, Map<String, Object> details) {
        return new ErrorResponse(code, message, details, Instant.now());
    }
}
