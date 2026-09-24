import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/theme/status_colors.dart';
import 'package:feedback_app/features/alerts/presentation/bloc/alerts_bloc.dart';
import 'package:feedback_app/features/feedback/presentation/pages/feedback_detail_page.dart';
import 'package:feedback_app/features/polls/presentation/pages/poll_detail_page.dart';
import 'package:feedback_app/shared/widgets/states.dart';

/// Alerts — the citizen's civic activity feed: report status changes and
/// polls worth voting on. Tap deep-links into the report or poll.
class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AlertsBloc>().add(const AlertsRefreshed());
  }

  void _refresh() {
    context.read<AlertsBloc>().add(const AlertsRefreshed());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Alerts',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
          Expanded(
            child: BlocConsumer<AlertsBloc, AlertsState>(
              listener: (context, state) {
                if (state is AlertsFailure) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is AlertsLoading) {
                  return const LoadingSkeleton();
                }
                if (state is AlertsFailure) {
                  return ErrorState(message: state.message, onRetry: _refresh);
                }
                final items =
                    state is AlertsLoaded ? state.items : const <AlertItem>[];
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'Nothing new',
                    subtitle: 'Report an issue or vote in a poll to see updates here.',
                    actionLabel: 'Refresh',
                    onAction: _refresh,
                  );
                }
                String? currentGroup;
                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final group = _groupOf(item.when);
                      final showHeader = group != currentGroup;
                      currentGroup = group;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 16, bottom: 8),
                              child: Text(group.toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                          letterSpacing: 1,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline)),
                            ),
                          ],
                          _AlertTile(
                              item: item, onTap: () => _open(item)),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _groupOf(DateTime? when) {
    if (when == null) return 'Earlier';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(when.year, when.month, when.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff <= 7) return 'This week';
    return 'Earlier';
  }

  void _open(AlertItem item) {
    if (item.reportId != null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FeedbackDetailPage(feedbackId: item.reportId!),
      ));
    } else if (item.pollId != null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PollDetailPage(pollId: item.pollId!),
      ));
    }
  }
}

class _AlertTile extends StatelessWidget {
  final AlertItem item;
  final VoidCallback onTap;

  const _AlertTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (item.kind) {
      AlertKind.reportStatus when item.status == 'RESOLVED' =>
        (Icons.verified_rounded, StatusColors.resolved),
      AlertKind.reportStatus => (
          Icons.campaign_rounded,
          StatusColors.forStatus(item.status ?? 'OPEN')
        ),
      AlertKind.pollClosing => (Icons.how_to_vote_rounded, scheme.tertiary),
      AlertKind.pollLive => (Icons.poll_rounded, scheme.primary),
    };
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        title: Text(item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(item.subtitle,
            maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing:
            Icon(Icons.chevron_right, color: scheme.outline, size: 20),
      ),
    );
  }
}
