package com.example.feedbackapp.notifications.controller;

import com.example.feedbackapp.common.api.ApiResponse;
import com.example.feedbackapp.common.error.UnauthorizedException;
import com.example.feedbackapp.notifications.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Service-to-service endpoint: feedback-service reports status changes.
 * Guarded by a shared X-Service-Key and NOT routed through the API gateway.
 */
@RestController
@RequestMapping("/internal/notifications")
@Tag(name = "Internal", description = "Service-to-service notification intake")
public class InternalNotificationController {

    private final NotificationService notificationService;
    private final String serviceKey;

    public InternalNotificationController(NotificationService notificationService,
                                          @Value("${internal.service-key:dev-service-key}") String serviceKey) {
        this.notificationService = notificationService;
        this.serviceKey = serviceKey;
    }

    public record ReportStatusRequest(@NotNull Long userId, String email, String name,
                                      @NotNull Long reportId, @NotBlank String reportTitle,
                                      @NotBlank String oldStatus, @NotBlank String newStatus) {
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a citizen notification for a report status change")
    public ApiResponse<Void> reportStatus(@Valid @RequestBody ReportStatusRequest request,
                                          @RequestHeader(value = "X-Service-Key", required = false) String key) {
        if (key == null || !constantTimeEquals(key, serviceKey)) {
            throw new UnauthorizedException("Invalid service key");
        }
        notificationService.createReportStatusNotification(new NotificationService.ReportStatusEvent(
                request.userId(), request.email(), request.name(),
                request.reportId(), request.reportTitle(),
                request.oldStatus(), request.newStatus()));
        return ApiResponse.ok(null, "Notification created");
    }

    private static boolean constantTimeEquals(String a, String b) {
        return java.security.MessageDigest.isEqual(a.getBytes(), b.getBytes());
    }
}
