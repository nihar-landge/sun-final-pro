package com.example.feedbackapp.auth.service;

import com.example.feedbackapp.auth.dto.LoginRequest;
import com.example.feedbackapp.auth.dto.RegisterRequest;
import com.example.feedbackapp.auth.entity.User;
import com.example.feedbackapp.auth.repository.UserRepository;
import com.example.feedbackapp.auth.security.JwtTokenProvider;
import com.example.feedbackapp.common.error.ConflictException;
import com.example.feedbackapp.common.error.UnauthorizedException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.time.Duration;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

class AuthServiceTest {

    private UserRepository userRepository;
    private JwtTokenProvider tokenProvider;
    private AuthService authService;

    @BeforeEach
    void setUp() {
        userRepository = Mockito.mock(UserRepository.class);
        tokenProvider = Mockito.mock(JwtTokenProvider.class);
        authService = new AuthService(userRepository, tokenProvider);
        when(tokenProvider.issueAccessToken(anyLong(), anyString(), anyString(), any()))
                .thenReturn("jwt-token");
        when(tokenProvider.accessTtlSeconds()).thenReturn(Duration.ofHours(24).toSeconds());
    }

    @Test
    @DisplayName("register hashes the password and defaults the role to CITIZEN")
    void registerHashesPassword() {
        when(userRepository.findByEmail("nihar@example.com")).thenReturn(Optional.empty());
        when(userRepository.save(any())).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            org.springframework.test.util.ReflectionTestUtils.setField(u, "id", 7L);
            if (u.getRole() == null) u.setRole(User.Role.CITIZEN); // mirrors @PrePersist
            return u;
        });

        var response = authService.register(new RegisterRequest("Nihar", "nihar@example.com", "s3cretPass!"));

        assertThat(response.role()).isEqualTo("CITIZEN");
        assertThat(response.email()).isEqualTo("nihar@example.com");
    }

    @Test
    @DisplayName("register rejects a duplicate email")
    void registerRejectsDuplicateEmail() {
        when(userRepository.findByEmail("nihar@example.com")).thenReturn(Optional.of(new User()));

        assertThatThrownBy(() -> authService.register(new RegisterRequest("Nihar", "nihar@example.com", "s3cretPass!")))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    @DisplayName("login issues a token for valid credentials")
    void loginHappyPath() {
        User user = new User();
        org.springframework.test.util.ReflectionTestUtils.setField(user, "id", 7L);
        user.setEmail("nihar@example.com");
        user.setPasswordHash(new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder().encode("s3cretPass!"));
        user.setRole(User.Role.CITIZEN);
        when(userRepository.findByEmail("nihar@example.com")).thenReturn(Optional.of(user));

        var token = authService.login(new LoginRequest("nihar@example.com", "s3cretPass!"));

        assertThat(token.accessToken()).isEqualTo("jwt-token");
        assertThat(token.tokenType()).isEqualTo("Bearer");
        assertThat(token.user().id()).isEqualTo(7L);
    }

    @Test
    @DisplayName("login rejects a wrong password and unknown emails with the same error")
    void loginRejectsBadCredentials() {
        User user = new User();
        org.springframework.test.util.ReflectionTestUtils.setField(user, "id", 7L);
        user.setEmail("nihar@example.com");
        user.setPasswordHash(new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder().encode("s3cretPass!"));
        user.setRole(User.Role.CITIZEN);
        when(userRepository.findByEmail("nihar@example.com")).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> authService.login(new LoginRequest("nihar@example.com", "wrong-pass")))
                .isInstanceOf(UnauthorizedException.class);

        when(userRepository.findByEmail("ghost@example.com")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> authService.login(new LoginRequest("ghost@example.com", "whatever123")))
                .isInstanceOf(UnauthorizedException.class);
    }
}
