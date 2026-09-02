package com.example.feedbackapp.auth.dto;

/**
 * devOtp is only populated when `app.otp.dev-echo=true` (dev profile) so the
 * flow can be exercised without a real SMS gateway.
 */
public record SendOtpResponse(String phone, int expiresInSeconds, String devOtp) {
}
