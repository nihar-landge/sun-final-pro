package com.example.feedbackapp.notifications.web;

import com.example.feedbackapp.common.web.GatewayUser;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

/**
 * FCM device-token registry: userId → current device token, stored in Redis
 * (keyed so a re-login replaces the old token; TTL keeps stale devices out).
 */
@Service
public class TokenRegistryService {

    private static final String KEY_PREFIX = "fcm:token:";
    private static final java.time.Duration TTL = java.time.Duration.ofDays(60);

    private final StringRedisTemplate redis;

    public TokenRegistryService(StringRedisTemplate redis) {
        this.redis = redis;
    }

    public void register(GatewayUser user, String token) {
        redis.opsForValue().set(KEY_PREFIX + user.id(), token, TTL);
    }

    /** Null when the user has no registered device (e.g. never opened the app). */
    public String tokenFor(Long userId) {
        return redis.opsForValue().get(KEY_PREFIX + userId);
    }
}
