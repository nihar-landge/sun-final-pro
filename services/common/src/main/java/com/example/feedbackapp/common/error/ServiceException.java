package com.example.feedbackapp.common.error;

/**
 * Base exception carrying a machine-readable {@link ErrorCode}. Service-level
 * exception handlers translate it into an {@link com.example.feedbackapp.common.api.ErrorResponse}.
 */
public abstract class ServiceException extends RuntimeException {

    private final ErrorCode errorCode;

    protected ServiceException(ErrorCode errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }

    public ErrorCode errorCode() {
        return errorCode;
    }
}
