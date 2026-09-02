package com.example.feedbackapp.auth.service;

import com.example.feedbackapp.auth.config.AppProperties;
import com.example.feedbackapp.auth.dto.SendOtpRequest;
import com.example.feedbackapp.auth.dto.SendOtpResponse;
import com.example.feedbackapp.auth.dto.TokenResponse;
import com.example.feedbackapp.auth.dto.UserResponse;
import com.example.feedbackapp.auth.dto.VerifyOtpRequest;
import com.example.feedbackapp.auth.entity.User;
import com.example.feedbackapp.auth.repository.UserRepository;
import com.example.feedbackapp.auth.security.JwtTokenProvider;
import com.example.feedbackapp.common.error.ErrorCode;
import com.example.feedbackapp.common.error.NotFoundException;
import com.example.feedbackapp.common.error.ServiceException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.Base64;
import java.util.Optional;

@Service
public class AuthService {

    private static final String REFRESH_KEY = "refresh:%s";
    private static final SecureRandom RANDOM = new SecureRandom();

    static class InvalidRefreshTokenException extends ServiceException {
        InvalidRefreshTokenException() {
            super(ErrorCode.UNAUTHORIZED, "Invalid or expired refresh token");
        }
    }

    private final UserRepository userRepository;
    private final OtpService otpService;
    private final JwtTokenProvider tokenProvider;
    private final StringRedisTemplate redis;
    private final AppProperties props;

    public AuthService(UserRepository userRepository,
                       OtpService otpService,
                       JwtTokenProvider tokenProvider,
                       StringRedisTemplate redis,
                       AppProperties props) {
        this.userRepository = userRepository;
        this.otpService = otpService;
        this.tokenProvider = tokenProvider;
        this.redis = redis;
        this.props = props;
    }

    public SendOtpResponse sendOtp(SendOtpRequest request) {
        String devOtp = otpService.sendOtp(request.phone());
        return new SendOtpResponse(request.phone(), (int) props.otp().ttl().toSeconds(), devOtp);
    }

    /** Verifies the OTP, upserts the user (register-on-first-login) and issues both tokens. */
    @Transactional
    public TokenResponse verifyAndLogin(VerifyOtpRequest request) {
        otpService.verifyOtp(request.phone(), request.code());

        User user = upsertUser(request.phone(), request.name());
        return issueTokens(user);
    }

    /** Exchanges a refresh token for a fresh pair (rotation: the old refresh token is revoked). */
    public TokenResponse refresh(String refreshToken) {
        Long userId = consumeRefreshToken(refreshToken);
        User user = userRepository.findById(userId)
                .orElseThrow(InvalidRefreshTokenException::new);
        return issueTokens(user);
    }

    public void logout(String refreshToken) {
        redis.delete(REFRESH_KEY.formatted(refreshToken));
    }

    public UserResponse me(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("User no longer exists"));
        return toResponse(user);
    }

    private User upsertUser(String phone, String name) {
        Optional<User> existing = userRepository.findByPhone(phone);
        if (existing.isPresent()) {
            User user = existing.get();
            if (name != null && !name.isBlank()) {
                user.setName(name.trim());
            }
            return userRepository.save(user);
        }
        User user = new User();
        user.setPhone(phone);
        user.setName(name == null || name.isBlank() ? "Citizen" : name.trim());
        return userRepository.save(user);
    }

    private TokenResponse issueTokens(User user) {
        String access = tokenProvider.issueAccessToken(user.getId(), user.getPhone(),
                user.getRole().name(), user.getName());
        String refresh = issueRefreshToken(user.getId());
        return TokenResponse.bearer(access, refresh, tokenProvider.accessTtlSeconds(), toResponse(user));
    }

    private String issueRefreshToken(Long userId) {
        byte[] bytes = new byte[48];
        RANDOM.nextBytes(bytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        redis.opsForValue().set(REFRESH_KEY.formatted(token), String.valueOf(userId), props.jwt().refreshTtl());
        return token;
    }

    private Long consumeRefreshToken(String refreshToken) {
        String key = REFRESH_KEY.formatted(refreshToken);
        String userId = redis.opsForValue().get(key);
        if (userId == null) {
            throw new InvalidRefreshTokenException();
        }
        redis.delete(key); // rotate
        return Long.valueOf(userId);
    }

    private UserResponse toResponse(User user) {
        return new UserResponse(user.getId(), user.getPhone(), user.getName(),
                user.getRole().name(), user.getCreatedAt());
    }
}
