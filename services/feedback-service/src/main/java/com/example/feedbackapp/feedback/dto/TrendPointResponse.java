package com.example.feedbackapp.feedback.dto;

/** One day of the reports trend (admin dashboard chart). */
public record TrendPointResponse(String day, long count) {
}
