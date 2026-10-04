package com.example.feedbackapp.auth.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.Optional;

/**
 * Issues and validates HS256 JWTs. The same secret is shared with the
 * API gateway so it can validate tokens without calling this service.
 * A single 24-hour access token — no refresh tokens.
 */
@Component
public class JwtTokenProvider {

    private final SecretKey key;
    private final String issuer;
    private final Duration accessTtl;

    public JwtTokenProvider(com.example.feedbackapp.auth.config.AppProperties props) {
        this.key = Keys.hmacShaKeyFor(props.jwt().secret().getBytes(StandardCharsets.UTF_8));
        this.issuer = props.jwt().issuer();
        this.accessTtl = props.jwt().accessTtl();
    }

    public String issueAccessToken(Long userId, String email, String role, String name) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .issuer(issuer)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(accessTtl)))
                .claim("email", email)
                .claim("role", role)
                .claim("name", name)
                .signWith(key)
                .compact();
    }

    /** Returns the verified claims, or empty if the token is invalid/expired. */
    public Optional<Claims> parse(String token) {
        try {
            return Optional.of(Jwts.parser()
                    .verifyWith(key)
                    .requireIssuer(issuer)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload());
        } catch (JwtException | IllegalArgumentException e) {
            return Optional.empty();
        }
    }

    public long accessTtlSeconds() {
        return accessTtl.toSeconds();
    }
}
