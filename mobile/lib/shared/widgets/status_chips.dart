import 'package:flutter/material.dart';

import 'package:feedback_app/core/theme/status_colors.dart';

/// Colored pill showing a feedback status (Open / In Review / Resolved).
class StatusChip extends StatelessWidget {
  final String status;
  final bool filled;

  const StatusChip({super.key, required this.status, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final color = StatusColors.forStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        StatusColors.label(status).toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }
}

/// LIVE / SOON / CLOSED pill for polls.
class PollStatusChip extends StatelessWidget {
  final String status;

  const PollStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, label) = switch (status) {
      'ACTIVE' => (scheme.primary, 'LIVE'),
      'SCHEDULED' => (scheme.tertiary, 'UPCOMING'),
      _ => (scheme.outline, 'CLOSED'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: color)),
    );
  }
}

/// VOTED pill shown on polls the current user participated in.
class VotedChip extends StatelessWidget {
  const VotedChip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: scheme.secondary),
          const SizedBox(width: 4),
          Text('VOTED',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: scheme.secondary)),
        ],
      ),
    );
  }
}
