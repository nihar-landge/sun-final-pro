package com.example.feedbackapp.gateway.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.cloud.gateway.filter.ratelimit.KeyResolver;
import reactor.core.publisher.Mono;

import java.util.Optional;

/**
 * Rate-limit key: client IP (honouring X-Forwarded-For from any upstream
 * proxy). Applied to the OTP-send route so one client cannot flood the
 * SMS budget.
 */
@Configuration
public class RateLimiterConfig {

    @Bean
    public KeyResolver clientIpKeyResolver() {
        return exchange -> Mono.just(
                Optional.ofNullable(exchange.getRequest().getHeaders().getFirst("X-Forwarded-For"))
                        .map(header -> header.split(",")[0].trim())
                        .orElseGet(() -> exchange.getRequest().getRemoteAddress() == null
                                ? "unknown"
                                : exchange.getRequest().getRemoteAddress().getAddress().getHostAddress()));
    }
}
