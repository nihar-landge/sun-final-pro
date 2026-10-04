package com.example.feedbackapp.common.error;

public class ValidationFailedException extends ServiceException {

    public ValidationFailedException(String message) {
        super(ErrorCode.VALIDATION_FAILED, message);
    }
}
