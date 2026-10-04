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
                        Duration.ofHours(24)));
        provider = new JwtTokenProvider(props);
    }

    @Test
    @DisplayName("issued token round-trips its claims")
    void tokenRoundTripsClaims() {
        String token = provider.issueAccessToken(42L, "nihar@example.com", "CITIZEN", "Nihar");

        Optional<Claims> claims = provider.parse(token);

        assertThat(claims).isPresent();
        assertThat(claims.get().getSubject()).isEqualTo("42");
        assertThat(claims.get().get("email", String.class)).isEqualTo("nihar@example.com");
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
                        Duration.ofHours(24)));
        JwtTokenProvider attacker = new JwtTokenProvider(otherProps);

        String foreign = attacker.issueAccessToken(1L, "evil@example.com", "ADMIN", "Evil");

        assertThat(provider.parse(foreign)).isEmpty();
    }
}
