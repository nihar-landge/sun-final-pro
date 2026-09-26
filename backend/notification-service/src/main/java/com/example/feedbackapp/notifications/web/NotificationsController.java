package com.example.feedbackapp.notifications.web;

import com.example.feedbackapp.common.api.ApiResponse;
import com.example.feedbackapp.common.error.ForbiddenException;
import com.example.feedbackapp.common.web.CurrentUser;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.notifications.entity.Notification;
import com.example.feedbackapp.notifications.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/notifications")
@Tag(name = "Notifications", description = "Citizen inbox (persistent) + admin event feed")
public class NotificationsController {

    private final NotificationStore store;
    private final TokenRegistryService tokenRegistry;
    private final NotificationService notificationService;

    public NotificationsController(NotificationStore store,
                                   TokenRegistryService tokenRegistry,
                                   NotificationService notificationService) {
        this.store = store;
        this.tokenRegistry = tokenRegistry;
        this.notificationService = notificationService;
    }

    public record RegisterTokenRequest(@NotBlank String token) {
    }

    @PostMapping("/register-token")
    @Operation(summary = "Register the caller's FCM device token")
    public ApiResponse<Void> registerToken(@Valid @RequestBody RegisterTokenRequest request,
                                           @CurrentUser GatewayUser user) {
        tokenRegistry.register(user, request.token());
        return ApiResponse.ok(null, "Push token registered");
    }

    // ---------- citizen inbox ----------

    public record InboxItem(Long id, String type, String title, String body,
                            Long refId, boolean unread, String createdAt) {

        static InboxItem from(Notification n) {
            return new InboxItem(n.getId(), n.getType(), n.getTitle(), n.getBody(),
                    n.getRefId(), n.isUnread(),
                    n.getCreatedAt() == null ? null : n.getCreatedAt().toString());
        }
    }

    @GetMapping("/inbox")
    @Operation(summary = "The caller's notification inbox, newest first")
    public ApiResponse<List<InboxItem>> inbox(@CurrentUser GatewayUser user) {
        return ApiResponse.ok(notificationService.inbox(user).stream()
                .map(InboxItem::from).toList());
    }

    @GetMapping("/unread-count")
    @Operation(summary = "Unread count for the caller (drives the badge)")
    public ApiResponse<Long> unreadCount(@CurrentUser GatewayUser user) {
        return ApiResponse.ok(notificationService.unreadCount(user));
    }

    @PostMapping("/{id}/read")
    @Operation(summary = "Mark one notification read (owner only)")
    public ApiResponse<Void> markRead(@PathVariable Long id, @CurrentUser GatewayUser user) {
        notificationService.markRead(id, user);
        return ApiResponse.ok(null, "Marked read");
    }

    @PostMapping("/read-all")
    @Operation(summary = "Mark all of the caller's notifications read")
    public ApiResponse<Integer> markAllRead(@CurrentUser GatewayUser user) {
        return ApiResponse.ok(notificationService.markAllRead(user), "All marked read");
    }

    // ---------- admin event feed ----------

    @GetMapping("/recent")
    @Operation(summary = "Most recent feedback events consumed from the broker (admin)")
    public ApiResponse<List<com.example.feedbackapp.common.event.FeedbackEvent>> recent(
            @CurrentUser GatewayUser user) {
        if (!user.isAdmin()) {
            throw new ForbiddenException("Admins only");
        }
        return ApiResponse.ok(store.recent());
    }
}
