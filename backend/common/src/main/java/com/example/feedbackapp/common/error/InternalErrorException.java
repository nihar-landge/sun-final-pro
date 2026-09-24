package com.example.feedbackapp.common.error;

public class InternalErrorException extends ServiceException {

    public InternalErrorException(String message) {
        super(ErrorCode.INTERNAL_ERROR, message);
    }
}
