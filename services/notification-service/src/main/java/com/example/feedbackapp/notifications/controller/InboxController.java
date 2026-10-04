package com.example.feedbackapp.notifications.controller;

import com.example.feedbackapp.common.api.ApiResponse;
import com.example.feedbackapp.common.web.CurrentUser;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.notifications.entity.Notification;
import com.example.feedbackapp.notifications.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * The citizen's notification inbox — read and mark-read APIs, served from
 * notificationdb (owned by this service).
 */
@RestController
@RequestMapping("/api/v1/notifications")
@Tag(name = "Notifications", description = "Citizen notification inbox")
public class InboxController {

    private final NotificationService notificationService;

    public InboxController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    public record InboxItem(Long id, String type, String title, String body,
                            Long refId, boolean unread, String createdAt) {

        static InboxItem from(Notification n) {
            return new InboxItem(n.getId(), n.getType(), n.getTitle(), n.getBody(),
                    n.getRefId(), n.isUnread(),
                    n.getCreatedAt() == null ? null : n.getCreatedAt().toString());
        }
    }

    @GetMapping
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "The caller's notification inbox, newest first")
    public ApiResponse<List<InboxItem>> inbox(@CurrentUser GatewayUser user) {
        return ApiResponse.ok(notificationService.inbox(user.id()).stream()
                .map(InboxItem::from).toList());
    }

    @GetMapping("/inbox")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Alias of GET /api/v1/notifications (mobile app path)")
    public ApiResponse<List<InboxItem>> inboxAlias(@CurrentUser GatewayUser user) {
        return inbox(user);
    }

    @GetMapping("/unread-count")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Unread count for the caller (drives the badge)")
    public ApiResponse<Long> unreadCount(@CurrentUser GatewayUser user) {
        return ApiResponse.ok(notificationService.unreadCount(user.id()));
    }

    @PutMapping("/{id}/read")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Mark one notification read (owner only)")
    public ApiResponse<Void> markRead(@PathVariable Long id, @CurrentUser GatewayUser user) {
        notificationService.markRead(id, user.id());
        return ApiResponse.ok(null, "Marked read");
    }

    /** POST alias kept for the mobile app until it moves to PUT. */
    @org.springframework.web.bind.annotation.PostMapping("/{id}/read")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "POST alias of PUT /{id}/read")
    public ApiResponse<Void> markReadPost(@PathVariable Long id, @CurrentUser GatewayUser user) {
        return markRead(id, user);
    }

    @PutMapping("/read-all")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Mark all of the caller's notifications read")
    public ApiResponse<Integer> markAllRead(@CurrentUser GatewayUser user) {
        return ApiResponse.ok(notificationService.markAllRead(user.id()), "All marked read");
    }

    @org.springframework.web.bind.annotation.PostMapping("/read-all")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "POST alias of PUT /read-all")
    public ApiResponse<Integer> markAllReadPost(@CurrentUser GatewayUser user) {
        return markAllRead(user);
    }
}
