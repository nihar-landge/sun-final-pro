package com.example.feedbackapp.auth.service;

import com.example.feedbackapp.auth.dto.UpdateRoleRequest;
import com.example.feedbackapp.auth.entity.User;
import com.example.feedbackapp.auth.repository.UserRepository;
import com.example.feedbackapp.auth.security.UserPrincipal;
import com.example.feedbackapp.common.error.ConflictException;
import com.example.feedbackapp.common.error.ForbiddenException;
import com.example.feedbackapp.common.error.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdminUserServiceTest {

    @Mock
    private UserRepository userRepository;

    private AdminUserService adminUserService;

    private static final UserPrincipal ADMIN_PRINCIPAL =
            new UserPrincipal(1L, "9999999999", "City Admin", "ADMIN");
    private static final UserPrincipal CITIZEN_PRINCIPAL =
            new UserPrincipal(2L, "9876543210", "Nihar", "CITIZEN");

    @BeforeEach
    void setUp() {
        adminUserService = new AdminUserService(userRepository);
    }

    private User user(long id, User.Role role) {
        User user = new User();
        ReflectionTestUtils.setField(user, "id", id);
        user.setEmail("user" + id + "@example.com");
        user.setName("User " + id);
        user.setRole(role);
        ReflectionTestUtils.setField(user, "createdAt", java.time.LocalDateTime.now());
        return user;
    }

    @Test
    @DisplayName("admin promotes a citizen to moderator")
    void promoteCitizen() {
        when(userRepository.findById(2L)).thenReturn(Optional.of(user(2, User.Role.CITIZEN)));
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        var response = adminUserService.changeRole(
                2L, UpdateRoleRequest.of("ADMIN"), ADMIN_PRINCIPAL);

        assertThat(response.role()).isEqualTo("ADMIN");
    }

    @Test
    @DisplayName("non-admin cannot change roles")
    void nonAdminRejected() {
        assertThatThrownBy(() -> adminUserService.changeRole(
                2L, UpdateRoleRequest.of("ADMIN"), CITIZEN_PRINCIPAL))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    @DisplayName("admin cannot demote themselves (locks out the account)")
    void selfDemotionRejected() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1, User.Role.ADMIN)));

        assertThatThrownBy(() -> adminUserService.changeRole(
                1L, UpdateRoleRequest.of("CITIZEN"), ADMIN_PRINCIPAL))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    @DisplayName("unknown user is 404")
    void unknownUser() {
        when(userRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adminUserService.changeRole(
                99L, UpdateRoleRequest.of("CITIZEN"), ADMIN_PRINCIPAL))
                .isInstanceOf(NotFoundException.class);
    }
}
