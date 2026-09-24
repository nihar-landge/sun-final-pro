package com.example.feedbackapp.feedback.dto;

/** Time-limited upload instructions: PUT the bytes to uploadUrl, then register objectKey. */
public record ImagePresignResponse(String uploadUrl, String objectKey) {
}
