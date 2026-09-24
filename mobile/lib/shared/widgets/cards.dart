import 'package:flutter/material.dart';

import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';
import 'package:feedback_app/features/polls/domain/entities/poll.dart';
import 'package:feedback_app/shared/widgets/status_chips.dart';

/// Poll card with result preview bars, vote count and countdown —
/// used on Home (featured) and the Polls tab.
class PollCard extends StatelessWidget {
  final Poll poll;
  final bool hasVoted;
  final VoidCallback onTap;

  const PollCard({
    super.key,
    required this.poll,
    this.hasVoted = false,
    required this.onTap,
  });

  String get _countdown {
    final diff = poll.endTime.difference(DateTime.now());
    if (diff.isNegative) return 'Ended';
    if (diff.inDays >= 1) return 'Ends in ${diff.inDays}d';
    if (diff.inHours >= 1) return 'Ends in ${diff.inHours}h';
    return 'Ends in ${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PollStatusChip(status: poll.status),
                  if (hasVoted) ...[
                    const SizedBox(width: 6),
                    const VotedChip(),
                  ],
                  const Spacer(),
                  Text('${poll.totalVotes} votes',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Text(poll.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (poll.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(poll.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 14),
              ...poll.options.take(3).map((option) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MiniBar(option: option, hasVoted: hasVoted),
                  )),
              if (poll.options.isEmpty)
                Text('${poll.options.length} options · $_countdown',
                    style: Theme.of(context).textTheme.bodySmall)
              else
                Row(
                  children: [
                    Icon(Icons.how_to_vote_outlined,
                        size: 14, color: scheme.outline),
                    const SizedBox(width: 4),
                    Text('${poll.totalVotes} participating  •  $_countdown',
                        style: Theme.of(context).textTheme.bodySmall),
                    const Spacer(),
                    Text('VIEW',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final PollOptionResult option;
  final bool hasVoted;

  const _MiniBar({required this.option, required this.hasVoted});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(option.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant)),
            ),
            Text('${option.percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: option.percentage / 100,
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(scheme.primary
                .withValues(alpha: hasVoted ? 1.0 : 0.55)),
          ),
        ),
      ],
    );
  }
}

/// Feedback report card — category icon, status, upvotes, distance.
class ReportCard extends StatelessWidget {
  final FeedbackItem item;
  final String? distanceLabel;
  final VoidCallback onTap;
  final VoidCallback? onUpvote;

  const ReportCard({
    super.key,
    required this.item,
    this.distanceLabel,
    required this.onTap,
    this.onUpvote,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_categoryIcon, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(item.category.name.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 0.6,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  StatusChip(status: item.status.name),
                ],
              ),
              const SizedBox(height: 10),
              Text(item.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(item.description,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (onUpvote != null)
                    _UpvotePill(count: item.upvotes, onTap: onUpvote!)
                  else
                    Row(
                      children: [
                        Icon(Icons.thumb_up_alt_outlined,
                            size: 15, color: scheme.outline),
                        const SizedBox(width: 4),
                        Text('${item.upvotes}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  if (distanceLabel != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.location_on_outlined,
                        size: 15, color: scheme.outline),
                    const SizedBox(width: 2),
                    Text(distanceLabel!,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _categoryIcon => switch (item.category) {
        FeedbackCategory.roads => Icons.construction,
        FeedbackCategory.water => Icons.water_drop_outlined,
        FeedbackCategory.electricity => Icons.bolt,
        FeedbackCategory.sanitation => Icons.cleaning_services_outlined,
        FeedbackCategory.transport => Icons.directions_bus_outlined,
        FeedbackCategory.other => Icons.report_problem_outlined,
      };
}

class _UpvotePill extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _UpvotePill({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.thumb_up_alt_rounded, size: 14, color: scheme.primary),
            const SizedBox(width: 4),
            Text('$count',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary)),
          ],
        ),
      ),
    );
  }
}
