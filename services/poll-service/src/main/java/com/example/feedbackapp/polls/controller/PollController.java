package com.example.feedbackapp.polls.controller;

import com.example.feedbackapp.common.api.ApiResponse;
import com.example.feedbackapp.common.web.CurrentUser;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.polls.dto.CreatePollRequest;
import com.example.feedbackapp.polls.dto.PollResponse;
import com.example.feedbackapp.polls.dto.PollSummaryResponse;
import com.example.feedbackapp.polls.dto.VoteRequest;
import com.example.feedbackapp.polls.service.PollService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/polls")
@Tag(name = "Polls", description = "Poll creation, one-person-one-vote participation and results")
public class PollController {

    private final PollService pollService;

    public PollController(PollService pollService) {
        this.pollService = pollService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a poll (admin)")
    public ApiResponse<PollResponse> create(@Valid @RequestBody CreatePollRequest request,
                                            @CurrentUser GatewayUser user) {
        return ApiResponse.ok(pollService.createPoll(request, user), "Poll created");
    }

    @GetMapping
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "List polls (status = active|closed|scheduled|all, default active)")
    public ApiResponse<List<PollSummaryResponse>> list(
            @RequestParam(name = "status", required = false) String status) {
        return ApiResponse.ok(pollService.listPolls(status));
    }

    @GetMapping("/{id}")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Poll details with live results (hasVoted reflects the caller)")
    public ApiResponse<PollResponse> get(@PathVariable Long id,
                                         @CurrentUser(required = false) GatewayUser user) {
        return ApiResponse.ok(pollService.getPollForUser(id, user));
    }

    @GetMapping("/{id}/results")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Live results for a poll (hasVoted reflects the caller)")
    public ApiResponse<PollResponse> results(@PathVariable Long id,
                                             @CurrentUser(required = false) GatewayUser user) {
        return ApiResponse.ok(pollService.getPollForUser(id, user));
    }

    @PostMapping("/{id}/vote")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Cast a vote (one per citizen per poll)")
    public ApiResponse<PollResponse> vote(@PathVariable Long id,
                                          @Valid @RequestBody VoteRequest request,
                                          @CurrentUser GatewayUser user) {
        return ApiResponse.ok(pollService.castVote(id, user, request.optionId()), "Vote recorded");
    }

    @PostMapping("/{id}/close")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Close a poll early (admin)")
    public ApiResponse<PollResponse> close(@PathVariable Long id, @CurrentUser GatewayUser user) {
        return ApiResponse.ok(pollService.closePoll(id, user), "Poll closed");
    }

    @GetMapping("/analytics/summary")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Participation analytics for the admin dashboard")
    public ApiResponse<com.example.feedbackapp.polls.dto.PollAnalyticsSummary> analytics(
            @CurrentUser GatewayUser user) {
        if (!user.isAdmin()) {
            throw new com.example.feedbackapp.common.error.ForbiddenException("Admins only");
        }
        return ApiResponse.ok(pollService.analyticsSummary());
    }
}
