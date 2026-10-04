package com.example.feedbackapp.feedback.controller;

import com.example.feedbackapp.common.api.ApiResponse;
import com.example.feedbackapp.common.web.CurrentUser;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.feedback.dto.CommentRequest;
import com.example.feedbackapp.feedback.dto.FeedbackDetailResponse;
import com.example.feedbackapp.feedback.dto.FeedbackSummaryResponse;
import com.example.feedbackapp.feedback.dto.NearbyFeedbackResponse;
import com.example.feedbackapp.feedback.dto.StatusUpdateRequest;
import com.example.feedbackapp.feedback.dto.SubmitFeedbackRequest;
import com.example.feedbackapp.feedback.entity.FeedbackCategory;
import com.example.feedbackapp.feedback.entity.FeedbackStatus;
import com.example.feedbackapp.feedback.service.FeedbackImageService;
import com.example.feedbackapp.feedback.service.FeedbackService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/feedback")
@Tag(name = "Feedback", description = "Geo-tagged civic feedback with community upvotes and admin workflow")
public class FeedbackController {

    private final FeedbackService feedbackService;
    private final FeedbackImageService imageService;

    public FeedbackController(FeedbackService feedbackService, FeedbackImageService imageService) {
        this.feedbackService = feedbackService;
        this.imageService = imageService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Submit feedback (optionally geo-tagged)")
    public ApiResponse<FeedbackSummaryResponse> submit(@Valid @RequestBody SubmitFeedbackRequest request,
                                                       @CurrentUser GatewayUser user) {
        return ApiResponse.ok(feedbackService.submit(request, user), "Feedback submitted");
    }

    @GetMapping
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "List feedback with optional category/status/search filters (paged)")
    public ApiResponse<Page<FeedbackSummaryResponse>> list(
            @RequestParam(required = false) FeedbackCategory category,
            @RequestParam(required = false) FeedbackStatus status,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @CurrentUser(required = false) GatewayUser user,
            @RequestParam(defaultValue = "false") boolean includeHidden) {
        return ApiResponse.ok(feedbackService.list(category, status, search, page, size, user, includeHidden));
    }

    @PatchMapping("/{id}")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Admin/moderator partial update: status, assignment, notes, hidden")
    public ApiResponse<FeedbackDetailResponse> adminUpdate(
            @PathVariable Long id,
            @Valid @RequestBody com.example.feedbackapp.feedback.dto.AdminUpdateFeedbackRequest request,
            @CurrentUser GatewayUser user) {
        return ApiResponse.ok(feedbackService.adminUpdate(id, request, user), "Report updated");
    }

    @PostMapping("/{id}/images/presign")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Get a time-limited direct-upload URL for one photo (author or staff)")
    public ApiResponse<com.example.feedbackapp.feedback.dto.ImagePresignResponse> presignImage(
            @PathVariable Long id,
            @Valid @RequestBody com.example.feedbackapp.feedback.dto.ImagePresignRequest request,
            @CurrentUser GatewayUser user) {
        var result = imageService.presignUpload(id, request.contentType(), user);
        return ApiResponse.ok(new com.example.feedbackapp.feedback.dto.ImagePresignResponse(
                result.uploadUrl(), result.objectKey()));
    }

    @PostMapping("/{id}/images")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Register an uploaded photo against the report")
    public ApiResponse<Void> registerImage(
            @PathVariable Long id,
            @Valid @RequestBody com.example.feedbackapp.feedback.dto.ImageRegisterRequest request,
            @CurrentUser GatewayUser user) {
        imageService.register(id, request.objectKey(), user);
        return ApiResponse.ok(null, "Photo attached");
    }

    @GetMapping("/admin/audit")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Status-transition audit trail (moderators and admins)")
    public ApiResponse<List<com.example.feedbackapp.feedback.dto.AuditEntryResponse>> audit(
            @RequestParam(defaultValue = "100") int limit,
            @CurrentUser GatewayUser user) {
        if (user == null || !user.isAdmin()) {
            throw new com.example.feedbackapp.common.error.ForbiddenException("Moderators or admins only");
        }
        return ApiResponse.ok(feedbackService.auditTrail(limit));
    }

    @GetMapping("/mine")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "The caller's own reports, newest first")
    public ApiResponse<List<FeedbackSummaryResponse>> mine(@CurrentUser GatewayUser user) {
        return ApiResponse.ok(feedbackService.myReports(user));
    }

    @GetMapping("/near-me")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Feedback within a radius, nearest first (MySQL spatial)")
    public ApiResponse<List<NearbyFeedbackResponse>> nearMe(
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(defaultValue = "5") double radiusKm,
            @RequestParam(required = false) FeedbackStatus status) {
        return ApiResponse.ok(feedbackService.nearMe(lat, lng, radiusKm, status));
    }

    @GetMapping("/{id}")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Feedback detail with comments and status history")
    public ApiResponse<FeedbackDetailResponse> get(@PathVariable Long id,
                                                   @CurrentUser(required = false) GatewayUser user) {
        return ApiResponse.ok(feedbackService.getDetail(id, user));
    }

    @PostMapping("/{id}/upvote")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Upvote feedback (one per citizen)")
    public ApiResponse<Void> upvote(@PathVariable Long id, @CurrentUser GatewayUser user) {
        feedbackService.upvote(id, user);
        return ApiResponse.ok(null, "Upvoted");
    }

    @PostMapping("/{id}/status")
    @PutMapping("/{id}/status")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Transition feedback status (admin; audited)")
    public ApiResponse<FeedbackDetailResponse> updateStatus(@PathVariable Long id,
                                                            @Valid @RequestBody StatusUpdateRequest request,
                                                            @CurrentUser GatewayUser user) {
        return ApiResponse.ok(feedbackService.transitionStatus(id, request, user), "Status updated");
    }

    @PostMapping("/{id}/comments")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Comment on feedback")
    public ApiResponse<FeedbackDetailResponse> comment(@PathVariable Long id,
                                                       @Valid @RequestBody CommentRequest request,
                                                       @CurrentUser GatewayUser user) {
        return ApiResponse.ok(feedbackService.addComment(id, request, user), "Comment added");
    }

    @GetMapping("/community-stats")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Community impact numbers (public - no user data)")
    public ApiResponse<com.example.feedbackapp.feedback.dto.CommunityStatsResponse> communityStats() {
        return ApiResponse.ok(feedbackService.communityStats());
    }

    @GetMapping("/admin/trend")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Daily reports trend for the last N days (moderators and admins)")
    public ApiResponse<List<com.example.feedbackapp.feedback.dto.TrendPointResponse>> trend(
            @RequestParam(defaultValue = "30") int days,
            @CurrentUser GatewayUser user) {
        if (user == null || !user.isAdmin()) {
            throw new com.example.feedbackapp.common.error.ForbiddenException("Moderators or admins only");
        }
        return ApiResponse.ok(feedbackService.trend(days));
    }

    @GetMapping("/analytics/summary")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Feedback analytics for the admin dashboard")
    public ApiResponse<com.example.feedbackapp.feedback.dto.FeedbackAnalyticsSummary> analytics(
            @CurrentUser GatewayUser user) {
        if (!user.isAdmin()) {
            throw new com.example.feedbackapp.common.error.ForbiddenException("Admins only");
        }
        return ApiResponse.ok(feedbackService.analyticsSummary());
    }
}
