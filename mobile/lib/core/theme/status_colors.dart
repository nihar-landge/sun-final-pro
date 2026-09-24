import 'package:flutter/material.dart';

/// Semantic status colors used across map pins, chips and timelines.
class StatusColors {
  StatusColors._();

  static const open = Color(0xFFE65100);     // orange
  static const inReview = Color(0xFFF9A825); // amber
  static const resolved = Color(0xFF2E7D32); // green

  static Color forStatus(String status) => switch (status) {
        'OPEN' => open,
        'IN_REVIEW' => inReview,
        'RESOLVED' => resolved,
        _ => Colors.blueGrey,
      };

  /// Label shown to citizens for a wire status.
  static String label(String status) => switch (status) {
        'OPEN' => 'Open',
        'IN_REVIEW' => 'In Review',
        'RESOLVED' => 'Resolved',
        _ => status,
      };
}
