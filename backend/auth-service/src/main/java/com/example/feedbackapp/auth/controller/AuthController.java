package com.example.feedbackapp.auth.controller;

import com.example.feedbackapp.auth.dto.RefreshTokenRequest;
import com.example.feedbackapp.auth.dto.SendOtpRequest;
import com.example.feedbackapp.auth.dto.SendOtpResponse;
import com.example.feedbackapp.auth.dto.TokenResponse;
import com.example.feedbackapp.auth.dto.UserResponse;
import com.example.feedbackapp.auth.dto.VerifyOtpRequest;
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
@Tag(name = "Authentication", description = "Phone OTP login and JWT lifecycle")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/otp/send")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Send a login OTP to the given phone number")
    public ApiResponse<SendOtpResponse> sendOtp(@Valid @RequestBody SendOtpRequest request) {
        return ApiResponse.ok(authService.sendOtp(request), "OTP sent");
    }

    @PostMapping("/otp/verify")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Verify the OTP and receive access + refresh tokens")
    public ApiResponse<TokenResponse> verifyOtp(@Valid @RequestBody VerifyOtpRequest request) {
        return ApiResponse.ok(authService.verifyAndLogin(request), "Logged in");
    }

    @PostMapping("/token/refresh")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Exchange a refresh token for a new token pair")
    public ApiResponse<TokenResponse> refresh(@Valid @RequestBody RefreshTokenRequest request) {
        return ApiResponse.ok(authService.refresh(request.refreshToken()));
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Revoke the given refresh token")
    public ApiResponse<Void> logout(@Valid @RequestBody RefreshTokenRequest request) {
        authService.logout(request.refreshToken());
        return ApiResponse.ok(null, "Logged out");
    }

    @GetMapping("/me")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Profile of the authenticated user (JWT required)")
    public ApiResponse<UserResponse> me(@AuthenticationPrincipal UserPrincipal principal) {
        return ApiResponse.ok(authService.me(principal.id()));
    }
}
