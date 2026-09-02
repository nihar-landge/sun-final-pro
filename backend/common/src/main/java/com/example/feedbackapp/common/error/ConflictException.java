package com.example.feedbackapp.common.error;

public class ConflictException extends ServiceException {

    public ConflictException(String message) {
        super(ErrorCode.CONFLICT, message);
    }
}
