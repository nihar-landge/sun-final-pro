package com.example.feedbackapp.auth.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

/**
 * Typed application settings (see application.yml under `app:`).
 * Secrets and TTLs are overridable via environment variables for each deployment.
 */
@ConfigurationProperties(prefix = "app")
public record AppProperties(Jwt jwt, Otp otp) {

    public record Jwt(String secret, String issuer, Duration accessTtl, Duration refreshTtl) {
    }

    public record Otp(int length, Duration ttl, boolean devEcho, int maxVerifyAttempts, Duration sendCooldown) {
    }
}
