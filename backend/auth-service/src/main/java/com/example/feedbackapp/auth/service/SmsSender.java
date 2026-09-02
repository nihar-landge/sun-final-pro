package com.example.feedbackapp.auth.service;

/**
 * Pluggable SMS delivery. Dev uses {@link LoggingSmsSender}; production
 * providers (Twilio, MSG91, ...) implement this interface.
 */
public interface SmsSender {

    void sendOtp(String phone, String code);
}
