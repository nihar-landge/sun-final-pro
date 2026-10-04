package com.example.feedbackapp.auth.controller;

import com.example.feedbackapp.auth.dto.LoginRequest;
import com.example.feedbackapp.auth.dto.RegisterRequest;
import com.example.feedbackapp.auth.dto.TokenResponse;
import com.example.feedbackapp.auth.dto.UserResponse;
import com.example.feedbackapp.auth.security.UserPrincipal;
import com.example.feedbackapp.auth.service.AuthService;
import com.example.feedbackapp.common.api.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication", description = "Email + password login and JWT lifecycle")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a citizen account (email + password)")
    public ApiResponse<UserResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ApiResponse.ok(authService.register(request), "Account created");
    }

    @PostMapping("/login")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Login with email + password and receive a 24h access token")
    public ApiResponse<TokenResponse> login(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.ok(authService.login(request), "Logged in");
    }

    /** Stateless JWT: logout is the client discarding the token. */
    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Logout (client discards the token; server keeps no session)")
    public ApiResponse<Void> logout() {
        return ApiResponse.ok(null, "Logged out");
    }

    @GetMapping("/me")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Profile of the authenticated user (JWT required)")
    public ApiResponse<UserResponse> me(@AuthenticationPrincipal UserPrincipal principal) {
        return ApiResponse.ok(authService.me(principal.id()));
    }
}
