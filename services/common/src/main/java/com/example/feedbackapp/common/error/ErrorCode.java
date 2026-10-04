package com.example.feedbackapp.common.error;

/**
 * Stable error codes shared across services so clients (and the gateway)
 * can branch on them without parsing messages.
 */
public enum ErrorCode {

    VALIDATION_FAILED("VAL-400"),
    UNAUTHORIZED("AUT-401"),
    FORBIDDEN("AUT-403"),
    OTP_INVALID("OTP-401"),
    OTP_RATE_LIMITED("OTP-429"),
    NOT_FOUND("RES-404"),
    CONFLICT("RES-409"),
    ALREADY_VOTED("POL-409"),
    INTERNAL_ERROR("SYS-500");

    private final String value;

    ErrorCode(String value) {
        this.value = value;
    }

    public String value() {
        return value;
    }
}
