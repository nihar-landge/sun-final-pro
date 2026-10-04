package com.example.feedbackapp.common.error;

public class AlreadyVotedException extends ServiceException {

    public AlreadyVotedException(String message) {
        super(ErrorCode.ALREADY_VOTED, message);
    }
}
