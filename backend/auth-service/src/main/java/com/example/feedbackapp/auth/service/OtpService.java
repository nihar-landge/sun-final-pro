package com.example.feedbackapp.auth.service;

import com.example.feedbackapp.auth.config.AppProperties;
import com.example.feedbackapp.common.error.ErrorCode;
import com.example.feedbackapp.common.error.ServiceException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Duration;

/**
 * OTP lifecycle stored in Redis:
 *   otp:{phone}        -> the active code, TTL = otp.ttl
 *   otp:rl:{phone}     -> send cooldown marker, TTL = otp.send-cooldown
 *   otp:att:{phone}    -> failed verification attempts, TTL = otp.ttl
 */
@Service
public class OtpService {

    private static final String OTP_KEY = "otp:%s";
    private static final String RATE_LIMIT_KEY = "otp:rl:%s";
    private static final String ATTEMPTS_KEY = "otp:att:%s";
    private static final SecureRandom RANDOM = new SecureRandom();

    static class OtpInvalidException extends ServiceException {
        OtpInvalidException(String message) {
            super(ErrorCode.OTP_INVALID, message);
        }
    }

    static class OtpRateLimitedException extends ServiceException {
        OtpRateLimitedException(String message) {
            super(ErrorCode.OTP_RATE_LIMITED, message);
        }
    }

    private final StringRedisTemplate redis;
    private final SmsSender smsSender;
    private final AppProperties.Otp settings;

    public OtpService(StringRedisTemplate redis, SmsSender smsSender, AppProperties props) {
        this.redis = redis;
        this.smsSender = smsSender;
        this.settings = props.otp();
    }

    /** Generates, stores and sends an OTP. Returns the code when dev echo is enabled, else null. */
    public String sendOtp(String phone) {
        if (redis.opsForValue().setIfAbsent(rateLimitKey(phone), "1", settings.sendCooldown()) == null) {
            throw new OtpRateLimitedException("Please wait before requesting another OTP");
        }

        String code = generateCode();
        redis.opsForValue().set(otpKey(phone), code, settings.ttl());
        redis.delete(attemptsKey(phone));
        smsSender.sendOtp(phone, code);

        return settings.devEcho() ? code : null;
    }

    /** Verifies the code, deleting it on success. Throws on mismatch, expiry or too many attempts. */
    public void verifyOtp(String phone, String code) {
        String stored = redis.opsForValue().get(otpKey(phone));
        if (stored == null) {
            throw new OtpInvalidException("OTP expired or not requested");
        }
        if (stored.equals(code)) {
            redis.delete(otpKey(phone));
            redis.delete(attemptsKey(phone));
            return;
        }

        Long attempts = redis.opsForValue().increment(attemptsKey(phone));
        redis.expire(attemptsKey(phone), settings.ttl());
        if (attempts != null && attempts >= settings.maxVerifyAttempts()) {
            redis.delete(otpKey(phone));
            redis.delete(attemptsKey(phone));
            throw new OtpRateLimitedException("Too many wrong attempts — request a new OTP");
        }
        throw new OtpInvalidException("Incorrect OTP");
    }

    private String generateCode() {
        StringBuilder sb = new StringBuilder(settings.length());
        for (int i = 0; i < settings.length(); i++) {
            sb.append(RANDOM.nextInt(10));
        }
        return sb.toString();
    }

    private String otpKey(String phone) {
        return OTP_KEY.formatted(phone);
    }

    private String rateLimitKey(String phone) {
        return RATE_LIMIT_KEY.formatted(phone);
    }

    private String attemptsKey(String phone) {
        return ATTEMPTS_KEY.formatted(phone);
    }
}
