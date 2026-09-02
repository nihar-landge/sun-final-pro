package com.example.feedbackapp.auth.service;

import com.example.feedbackapp.auth.dto.AdminUserResponse;
import com.example.feedbackapp.auth.dto.UpdateRoleRequest;
import com.example.feedbackapp.auth.entity.User;
import com.example.feedbackapp.auth.repository.UserRepository;
import com.example.feedbackapp.auth.security.UserPrincipal;
import com.example.feedbackapp.common.error.ConflictException;
import com.example.feedbackapp.common.error.ForbiddenException;
import com.example.feedbackapp.common.error.NotFoundException;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

/**
 * Admin user management: listing/searching users and role transitions.
 * The caller (resolved from the JWT) must be an ADMIN.
 */
@Service
public class AdminUserService {

    private final UserRepository userRepository;

    public AdminUserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public Page<AdminUserResponse> listUsers(User.Role role, String search, int page, int size) {
        Specification<User> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (role != null) {
                predicates.add(cb.equal(root.get("role"), role));
            }
            if (search != null && !search.isBlank()) {
                String term = "%" + search.toLowerCase() + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(cb.coalesce(root.get("name"), "")), term),
                        cb.like(root.get("phone"), "%" + search + "%")));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        };
        return userRepository
                .findAll(spec, PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")))
                .map(AdminUserResponse::from);
    }

    @Transactional
    public AdminUserResponse changeRole(Long userId, UpdateRoleRequest request, UserPrincipal caller) {
        if (caller == null || !"ADMIN".equals(caller.role())) {
            throw new ForbiddenException("Only admins can change roles");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("User %d not found".formatted(userId)));

        User.Role newRole = request.toRole();
        if (user.getId().equals(caller.id()) && newRole != User.Role.ADMIN) {
            throw new ConflictException("You cannot change your own admin role");
        }

        user.setRole(newRole);
        return AdminUserResponse.from(userRepository.save(user));
        // Note: the role lives in the JWT claim, so a demoted user keeps their
        // old authority until their access token expires (max 15 min).
    }
}
