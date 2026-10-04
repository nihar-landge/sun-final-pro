package com.example.feedbackapp.auth.controller;

import com.example.feedbackapp.auth.dto.AdminUserResponse;
import com.example.feedbackapp.auth.dto.UpdateRoleRequest;
import com.example.feedbackapp.auth.entity.User;
import com.example.feedbackapp.auth.security.UserPrincipal;
import com.example.feedbackapp.auth.service.AdminUserService;
import com.example.feedbackapp.common.api.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth/admin")
@Tag(name = "User Management", description = "Admin-only user listing and role management")
public class AdminUserController {

    private final AdminUserService adminUserService;

    public AdminUserController(AdminUserService adminUserService) {
        this.adminUserService = adminUserService;
    }

    @GetMapping("/users")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "List users with optional role filter and search (admin)")
    public ApiResponse<Page<AdminUserResponse>> listUsers(
            @RequestParam(required = false) User.Role role,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal UserPrincipal principal) {
        requireAdmin(principal);
        return ApiResponse.ok(adminUserService.listUsers(role, search, page, size));
    }

    @PatchMapping("/users/{id}/role")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Change a user's role (admin; cannot demote yourself)")
    public ApiResponse<AdminUserResponse> changeRole(@PathVariable Long id,
                                                     @Valid @RequestBody UpdateRoleRequest request,
                                                     @AuthenticationPrincipal UserPrincipal principal) {
        requireAdmin(principal);
        return ApiResponse.ok(adminUserService.changeRole(id, request, principal), "Role updated");
    }

    private void requireAdmin(UserPrincipal principal) {
        if (principal == null || !"ADMIN".equals(principal.role())) {
            throw new com.example.feedbackapp.common.error.ForbiddenException("Admins only");
        }
    }
}
