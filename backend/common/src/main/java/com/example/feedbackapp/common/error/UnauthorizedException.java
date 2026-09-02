package com.example.feedbackapp.common.error;

public class UnauthorizedException extends ServiceException {

    public UnauthorizedException(String message) {
        super(ErrorCode.UNAUTHORIZED, message);
    }
}
