package com.example.feedbackapp.auth.service;

import com.example.feedbackapp.auth.config.AppProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.startsWith;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OtpServiceTest {

    @Mock
    private StringRedisTemplate redis;
    @Mock
    private ValueOperations<String, String> valueOps;
    @Mock
    private SmsSender smsSender;

    private OtpService otpService;

    @BeforeEach
    void setUp() {
        AppProperties props = new AppProperties(
                new AppProperties.Jwt("secret", "test", Duration.ofMinutes(15), Duration.ofDays(30)),
                new AppProperties.Otp(6, Duration.ofMinutes(5), true, 5, Duration.ofSeconds(60)));
        otpService = new OtpService(redis, smsSender, props);
        lenient().when(redis.opsForValue()).thenReturn(valueOps);
    }

    @Test
    @DisplayName("sendOtp stores the code in Redis, sends SMS and echoes it in dev mode")
    void sendOtpStoresAndEchoesCode() {
        when(valueOps.setIfAbsent(anyString(), anyString(), any(Duration.class))).thenReturn(true);

        String code = otpService.sendOtp("9876543210");

        assertThat(code).hasSize(6).containsOnlyDigits();
        verify(valueOps).set(startsWith("otp:9876543210"), eq(code), eq(Duration.ofMinutes(5)));
        verify(smsSender).sendOtp("9876543210", code);
    }

    @Test
    @DisplayName("sendOtp is rate-limited when the cooldown marker already exists")
    void sendOtpRateLimited() {
        // NX-fail: the key already existed, so Redis returns FALSE.
        when(valueOps.setIfAbsent(anyString(), anyString(), any(Duration.class))).thenReturn(false);

        assertThatThrownBy(() -> otpService.sendOtp("9876543210"))
                .isInstanceOf(OtpService.OtpRateLimitedException.class);
        verify(smsSender, never()).sendOtp(anyString(), anyString());
    }

    @Test
    @DisplayName("sendOtp arms the cooldown marker with the configured TTL")
    void sendOtpArmsCooldownTtl() {
        when(valueOps.setIfAbsent(anyString(), anyString(), any(Duration.class))).thenReturn(true);

        otpService.sendOtp("9876543210");

        verify(valueOps).setIfAbsent("otp:rl:9876543210", "1", Duration.ofSeconds(60));
    }

    @Test
    @DisplayName("verifyOtp deletes the code on success")
    void verifyCorrectCodeDeletesKey() {
        when(valueOps.get("otp:9876543210")).thenReturn("123456");

        otpService.verifyOtp("9876543210", "123456");

        verify(redis).delete("otp:9876543210");
        verify(redis).delete("otp:att:9876543210");
    }

    @Test
    @DisplayName("verifyOtp increments attempts on a wrong code")
    void verifyWrongCodeIncrementsAttempts() {
        when(valueOps.get("otp:9876543210")).thenReturn("123456");
        when(valueOps.increment("otp:att:9876543210")).thenReturn(1L);

        assertThatThrownBy(() -> otpService.verifyOtp("9876543210", "654321"))
                .isInstanceOf(OtpService.OtpInvalidException.class);
        verify(valueOps).increment("otp:att:9876543210");
    }

    @Test
    @DisplayName("too many wrong attempts revokes the OTP")
    void tooManyAttemptsRevokesOtp() {
        when(valueOps.get("otp:9876543210")).thenReturn("123456");
        when(valueOps.increment("otp:att:9876543210")).thenReturn(5L);

        assertThatThrownBy(() -> otpService.verifyOtp("9876543210", "654321"))
                .isInstanceOf(OtpService.OtpRateLimitedException.class);
        verify(redis).delete("otp:9876543210");
    }

    @Test
    @DisplayName("expired OTP (missing key) is rejected")
    void expiredOtpRejected() {
        when(valueOps.get("otp:9876543210")).thenReturn(null);

        assertThatThrownBy(() -> otpService.verifyOtp("9876543210", "123456"))
                .isInstanceOf(OtpService.OtpInvalidException.class);
    }
}
