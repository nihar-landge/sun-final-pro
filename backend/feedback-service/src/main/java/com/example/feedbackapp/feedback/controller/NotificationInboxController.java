package com.example.feedbackapp.feedback.controller;

import com.example.feedbackapp.common.api.ApiResponse;
import com.example.feedbackapp.common.error.NotFoundException;
import com.example.feedbackapp.common.web.CurrentUser;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.feedback.entity.Notification;
import com.example.feedbackapp.feedback.service.NotificationInboxService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * The citizen's notification inbox — served by feedback-service because the
 * inbox rows live in feedbackdb, written in the same transaction as the
 * status changes that cause them.
 */
@RestController
@RequestMapping("/api/v1/notifications")
@Tag(name = "Notifications", description = "Citizen notification inbox + FCM device token registration")
public class NotificationInboxController {

    private final NotificationInboxService inboxService;

    public NotificationInboxController(NotificationInboxService inboxService) {
        this.inboxService = inboxService;
    }

    public record InboxItem(Long id, String type, String title, String body,
                            Long refId, boolean unread, String createdAt) {

        static InboxItem from(Notification n) {
            return new InboxItem(n.getId(), n.getType(), n.getTitle(), n.getBody(),
                    n.getRefId(), n.isUnread(),
                    n.getCreatedAt() == null ? null : n.getCreatedAt().toString());
        }
    }

    public record RegisterTokenRequest(@NotBlank String token) {
    }

    @GetMapping("/inbox")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "The caller's notification inbox, newest first")
    public ApiResponse<List<InboxItem>> inbox(@CurrentUser GatewayUser user) {
        return ApiResponse.ok(inboxService.inbox(user.id()).stream()
                .map(InboxItem::from).toList());
    }

    @GetMapping("/unread-count")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Unread count for the caller (drives the badge)")
    public ApiResponse<Long> unreadCount(@CurrentUser GatewayUser user) {
        return ApiResponse.ok(inboxService.unreadCount(user.id()));
    }

    @PostMapping("/{id}/read")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Mark one notification read (owner only)")
    public ApiResponse<Void> markRead(@PathVariable Long id, @CurrentUser GatewayUser user) {
        inboxService.markRead(id, user.id());
        return ApiResponse.ok(null, "Marked read");
    }

    @PostMapping("/read-all")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Mark all of the caller's notifications read")
    public ApiResponse<Integer> markAllRead(@CurrentUser GatewayUser user) {
        return ApiResponse.ok(inboxService.markAllRead(user.id()), "All marked read");
    }

    @PostMapping("/register-token")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Register the caller's FCM device token")
    public ApiResponse<Void> registerToken(@Valid @RequestBody RegisterTokenRequest request,
                                           @CurrentUser GatewayUser user) {
        inboxService.registerToken(user.id(), request.token());
        return ApiResponse.ok(null, "Push token registered");
    }
}
