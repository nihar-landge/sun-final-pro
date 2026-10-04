package com.example.feedbackapp.gateway.security;

import com.example.feedbackapp.common.api.ErrorResponse;
import com.example.feedbackapp.common.error.ErrorCode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Optional;

/**
 * Validates JWTs at the edge for business APIs and forwards the verified
 * identity to downstream services via trusted X-User-* headers (any
 * client-supplied X-User-* header is stripped first).
 *
 * Public: register/login, the community-stats teaser, WebSocket upgrades
 * and actuator.
 */
@Component
public class JwtAuthGlobalFilter implements GlobalFilter, Ordered {

    private static final AntPathMatcher PATH_MATCHER = new AntPathMatcher();
    private static final List<String> PUBLIC_PATHS = List.of(
            "/api/v1/auth/register",
            "/api/v1/auth/login",
            "/api/v1/feedback/community-stats",
            "/uploads/**",
            "/ws/**",
            "/actuator/**");

    private static final String BEARER_PREFIX = "Bearer ";

    private final SecretKey key;
    private final String issuer;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public JwtAuthGlobalFilter(JwtProperties props) {
        this.key = Keys.hmacShaKeyFor(props.secret().getBytes(StandardCharsets.UTF_8));
        this.issuer = props.issuer();
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        String path = request.getPath().value();

        if (isPublic(path)) {
            return chain.filter(sanitize(exchange));
        }

        Optional<String> token = extractBearerToken(request);
        if (token.isEmpty()) {
            return reject(exchange, HttpStatus.UNAUTHORIZED, "Missing or malformed Authorization header");
        }

        Optional<Claims> claims = parse(token.get());
        if (claims.isEmpty()) {
            return reject(exchange, HttpStatus.UNAUTHORIZED, "Invalid or expired token");
        }

        ServerHttpRequest authenticated = sanitize(exchange).getRequest().mutate()
                .header("X-User-Id", claims.get().getSubject())
                .header("X-User-Role", String.valueOf(claims.get().get("role", String.class)))
                .header("X-User-Name", String.valueOf(claims.get().get("name", String.class)))
                .header("X-User-Email", String.valueOf(claims.get().get("email", String.class)))
                .build();
        return chain.filter(exchange.mutate().request(authenticated).build());
    }

    @Override
    public int getOrder() {
        return -100; // run before routing filters
    }

    private boolean isPublic(String path) {
        return PUBLIC_PATHS.stream().anyMatch(pattern -> PATH_MATCHER.match(pattern, path));
    }

    /** Removes client-supplied identity headers so they cannot be spoofed. */
    private ServerWebExchange sanitize(ServerWebExchange exchange) {
        ServerHttpRequest clean = exchange.getRequest().mutate()
                .headers(headers -> {
                    headers.remove("X-User-Id");
                    headers.remove("X-User-Role");
                    headers.remove("X-User-Name");
                    headers.remove("X-User-Email");
                })
                .build();
        return exchange.mutate().request(clean).build();
    }

    private Optional<String> extractBearerToken(ServerHttpRequest request) {
        String header = request.getHeaders().getFirst("Authorization");
        if (header == null || !header.startsWith(BEARER_PREFIX)) {
            return Optional.empty();
        }
        return Optional.of(header.substring(BEARER_PREFIX.length()));
    }

    private Optional<Claims> parse(String token) {
        try {
            return Optional.of(Jwts.parser()
                    .verifyWith(key)
                    .requireIssuer(issuer)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload());
        } catch (Exception e) {
            return Optional.empty();
        }
    }

    private Mono<Void> reject(ServerWebExchange exchange, HttpStatus status, String message) {
        ServerHttpResponse response = exchange.getResponse();
        response.setStatusCode(status);
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        ErrorResponse error = ErrorResponse.of(
                status == HttpStatus.UNAUTHORIZED ? ErrorCode.UNAUTHORIZED.value() : ErrorCode.FORBIDDEN.value(),
                message);
        byte[] body;
        try {
            body = objectMapper.writeValueAsBytes(error);
        } catch (Exception e) {
            body = message.getBytes(StandardCharsets.UTF_8);
        }
        DataBuffer buffer = response.bufferFactory().wrap(body);
        return response.writeWith(Mono.just(buffer));
    }
}
