package com.example.feedbackapp.auth.service;

import com.example.feedbackapp.auth.dto.LoginRequest;
import com.example.feedbackapp.auth.dto.RegisterRequest;
import com.example.feedbackapp.auth.dto.TokenResponse;
import com.example.feedbackapp.auth.dto.UserResponse;
import com.example.feedbackapp.auth.entity.User;
import com.example.feedbackapp.auth.repository.UserRepository;
import com.example.feedbackapp.auth.security.JwtTokenProvider;
import com.example.feedbackapp.common.error.ConflictException;
import com.example.feedbackapp.common.error.NotFoundException;
import com.example.feedbackapp.common.error.UnauthorizedException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final JwtTokenProvider tokenProvider;
    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public AuthService(UserRepository userRepository, JwtTokenProvider tokenProvider) {
        this.userRepository = userRepository;
        this.tokenProvider = tokenProvider;
    }

    @Transactional
    public UserResponse register(RegisterRequest request) {
        String email = request.email().trim().toLowerCase();
        if (userRepository.findByEmail(email).isPresent()) {
            throw new ConflictException("An account with this email already exists");
        }
        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setName(request.name().trim());
        return UserResponse.from(userRepository.save(user));
    }

    @Transactional(readOnly = true)
    public TokenResponse login(LoginRequest request) {
        String email = request.email().trim().toLowerCase();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("Invalid email or password"));
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new UnauthorizedException("Invalid email or password");
        }
        String access = tokenProvider.issueAccessToken(user.getId(), user.getEmail(),
                user.getRole().name(), user.getName());
        return TokenResponse.bearer(access, tokenProvider.accessTtlSeconds(), UserResponse.from(user));
    }

    public UserResponse me(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("User no longer exists"));
        return UserResponse.from(user);
    }
}
