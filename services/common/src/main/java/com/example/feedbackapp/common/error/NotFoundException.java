package com.example.feedbackapp.common.error;

public class NotFoundException extends ServiceException {

    public NotFoundException(String message) {
        super(ErrorCode.NOT_FOUND, message);
    }
}
