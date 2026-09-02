package com.example.feedbackapp.notifications.web;

import com.example.feedbackapp.common.api.ApiResponse;
import com.example.feedbackapp.common.event.FeedbackEvent;
import com.example.feedbackapp.common.error.ForbiddenException;
import com.example.feedbackapp.common.web.CurrentUser;
import com.example.feedbackapp.common.web.GatewayUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/notifications")
@Tag(name = "Notifications", description = "Recent domain events consumed from the message broker")
public class NotificationsController {

    private final NotificationStore store;

    public NotificationsController(NotificationStore store) {
        this.store = store;
    }

    @GetMapping("/recent")
    @Operation(summary = "Most recent feedback events (admin)")
    public ApiResponse<List<FeedbackEvent>> recent(@CurrentUser GatewayUser user) {
        if (!user.isAdmin()) {
            throw new ForbiddenException("Admins only");
        }
        return ApiResponse.ok(store.recent());
    }
}
