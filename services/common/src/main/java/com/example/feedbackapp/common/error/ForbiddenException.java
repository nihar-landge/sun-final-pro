package com.example.feedbackapp.common.error;

public class ForbiddenException extends ServiceException {

    public ForbiddenException(String message) {
        super(ErrorCode.FORBIDDEN, message);
    }
}
