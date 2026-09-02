package com.example.feedbackapp.auth.security;

import io.jsonwebtoken.Claims;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

class JwtTokenProviderTest {

    private JwtTokenProvider provider;

    @BeforeEach
    void setUp() {
        var props = new com.example.feedbackapp.auth.config.AppProperties(
                new com.example.feedbackapp.auth.config.AppProperties.Jwt(
                        "unit-test-secret-key-that-is-long-enough-32ch",
                        "test-issuer",
                        Duration.ofMinutes(15),
                        Duration.ofDays(30)),
                new com.example.feedbackapp.auth.config.AppProperties.Otp(
                        6, Duration.ofMinutes(5), true, 5, Duration.ofSeconds(60)));
        provider = new JwtTokenProvider(props);
    }

    @Test
    @DisplayName("issued token round-trips its claims")
    void tokenRoundTripsClaims() {
        String token = provider.issueAccessToken(42L, "9876543210", "CITIZEN", "Nihar");

        Optional<Claims> claims = provider.parse(token);

        assertThat(claims).isPresent();
        assertThat(claims.get().getSubject()).isEqualTo("42");
        assertThat(claims.get().get("phone", String.class)).isEqualTo("9876543210");
        assertThat(claims.get().get("role", String.class)).isEqualTo("CITIZEN");
        assertThat(claims.get().get("name", String.class)).isEqualTo("Nihar");
        assertThat(claims.get().getIssuer()).isEqualTo("test-issuer");
    }

    @Test
    @DisplayName("garbage tokens are rejected")
    void garbageTokenRejected() {
        assertThat(provider.parse("not-a-token")).isEmpty();
    }

    @Test
    @DisplayName("tokens signed with a different secret are rejected")
    void foreignSignatureRejected() {
        var otherProps = new com.example.feedbackapp.auth.config.AppProperties(
                new com.example.feedbackapp.auth.config.AppProperties.Jwt(
                        "a-completely-different-secret-key-32ch!!",
                        "test-issuer",
                        Duration.ofMinutes(15),
                        Duration.ofDays(30)),
                new com.example.feedbackapp.auth.config.AppProperties.Otp(
                        6, Duration.ofMinutes(5), true, 5, Duration.ofSeconds(60)));
        JwtTokenProvider attacker = new JwtTokenProvider(otherProps);

        String foreign = attacker.issueAccessToken(1L, "1111111111", "ADMIN", "Evil");

        assertThat(provider.parse(foreign)).isEmpty();
    }
}
