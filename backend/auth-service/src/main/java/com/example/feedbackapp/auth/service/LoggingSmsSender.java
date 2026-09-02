package com.example.feedbackapp.auth.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Development implementation: logs the OTP instead of sending a real SMS.
 */
@Component
public class LoggingSmsSender implements SmsSender {

    private static final Logger log = LoggerFactory.getLogger(LoggingSmsSender.class);

    @Override
    public void sendOtp(String phone, String code) {
        log.info("[DEV SMS] OTP for {} is {}", phone, code);
    }
}
