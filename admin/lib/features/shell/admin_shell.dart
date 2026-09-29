import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_admin/core/theme.dart';
import 'package:feedback_admin/main.dart' show AdminGate;
import 'package:feedback_admin/features/analytics/admin_analytics_bloc.dart';
import 'package:feedback_admin/features/auth/admin_auth_bloc.dart';
import 'package:feedback_admin/features/map/map_page.dart';
import 'package:feedback_admin/features/polls/polls_page.dart';
import 'package:feedback_admin/features/reports/reports_bloc.dart';
import 'package:feedback_admin/features/reports/reports_page.dart';
import 'package:feedback_admin/features/analytics/analytics_page.dart' show AnalyticsPage, UsersPage;
import 'package:feedback_admin/features/audit/audit_page.dart' show AuditPage;

/// Desktop-first municipal operations console with a left sidebar.
/// Moderators see everything except Users (server enforces ADMIN-only there).
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthBloc>().state;
    final isAdmin = auth is AdminAuthenticated && auth.isAdmin;
    final staffName = auth is AdminAuthenticated ? auth.name : '';
    final staffRole = auth is AdminAuthenticated ? auth.role : '';

    const destinations = [
      (Icons.dashboard_outlined, 'Dashboard'),
      (Icons.campaign_outlined, 'Reports'),
      (Icons.poll_outlined, 'Polls'),
      (Icons.map_outlined, 'Map'),
      (Icons.insights_outlined, 'Analytics'),
      (Icons.manage_accounts_outlined, 'Users'),
      (Icons.history_outlined, 'Audit Log'),
    ];
    final visible = [
      for (var i = 0; i < destinations.length; i++)
        if (isAdmin || i != 5) i // Users admin-only
    ];

    final pages = <Widget>[
      const DashboardPage(),
      const ReportsPage(),
      const PollsPage(),
      const MapPage(),
      const AnalyticsPage(),
      const UsersPage(),
      const AuditPage(),
    ];

    return Scaffold(
      body: Row(
        children: [
          // ---------- sidebar ----------
          Container(
            width: 230,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.monitor_heart_outlined,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text('CivicPulse',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                for (final i in visible)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      selected: _index == i,
                      selectedTileColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      leading: Icon(destinations[i].$1, size: 20),
                      title: Text(destinations[i].$2,
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w600)),
                      onTap: () => setState(() => _index = i),
                    ),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(staffName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(staffRole,
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(36),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Sign out', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          context.read<AdminAuthBloc>().add(AdminLogoutRequested());
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AdminGate()),
                            (_) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // ---------- content ----------
          Expanded(
            child: BlocListener<ReportsBloc, ReportsState>(
              listener: (context, state) {
                if (state is ReportsLoaded && state.message != null) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(state.message!)));
                } else if (state is ReportsFailure) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              child: IndexedStack(index: _index, children: pages),
            ),
          ),
        ],
      ),
    );
  }
}

// The pages live in their own files; Dashboard composes the analytics bloc.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AdminAnalyticsBloc>().state;
    if (analytics is AdminAnalyticsFailure) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load the dashboard: ${analytics.message}'),
            TextButton(
              onPressed: () => context
                  .read<AdminAnalyticsBloc>()
                  .add(const AdminAnalyticsRefreshed()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (analytics is! AdminAnalyticsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final a = analytics.analytics;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Overview',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                  label: 'Open Reports',
                  value: '${a.feedbackStats.byStatus['OPEN'] ?? 0}',
                  icon: Icons.campaign_outlined,
                  color: statusColor['OPEN']),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                  label: 'In Review',
                  value: '${a.feedbackStats.byStatus['IN_REVIEW'] ?? 0}',
                  icon: Icons.pending_outlined,
                  color: statusColor['IN_REVIEW']),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                  label: 'Resolved',
                  value: '${a.feedbackStats.byStatus['RESOLVED'] ?? 0}',
                  icon: Icons.verified_outlined,
                  color: statusColor['RESOLVED']),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                  label: 'Active Polls',
                  value: '${a.pollStats.activePolls}',
                  icon: Icons.poll_outlined,
                  color: pollStatusColor['ACTIVE']),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                  label: 'Total Votes',
                  value: '${a.pollStats.totalVotes}',
                  icon: Icons.how_to_vote_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                  label: 'Avg Resolution',
                  value:
                      '${a.feedbackStats.avgResolutionHours ?? '—'} h',
                  icon: Icons.timer_outlined,
                  color: Colors.indigo),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report status',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                DistributionBars(data: a.feedbackStats.byStatus),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reports - last 14 days',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final point in a.trend)
                        Expanded(
                          child: Tooltip(
                            message: '${_shortDay(point.day)}: ${point.count}',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (point.count > 0)
                                    Text('${point.count}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall),
                                  const SizedBox(height: 2),
                                  Container(
                                    height: _barHeight(point.count, a.trend),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reports by category',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                DistributionBars(data: a.feedbackStats.byCategory),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Live event feed (RabbitMQ)',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => context
                          .read<AdminAnalyticsBloc>()
                          .add(const AdminAnalyticsRefreshed()),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (a.events.isEmpty)
                  const Text('No events consumed yet.')
                else
                  ...a.events.take(8).map((event) => ListTile(
                        dense: true,
                        leading: Icon(
                          event.type == 'feedback.created'
                              ? Icons.add_circle_outline
                              : Icons.sync,
                          color: event.type == 'feedback.created'
                              ? Colors.indigo
                              : Colors.green,
                        ),
                        title: Text(event.title),
                        subtitle: Text(event.type == 'feedback.status.changed'
                            ? '${event.oldStatus} → ${event.newStatus}'
                            : 'New report submitted'),
                        trailing: Text(_clock(event.occurredAt)),
                      )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


double _barHeight(int count, List<TrendPoint> trend) {
  final max = trend.fold<int>(1, (m, p) => p.count > m ? p.count : m);
  return 12.0 + (count / max) * 88.0;
}

/// ISO "2026-09-01" → "09-01"; falls back to the raw value on short payloads.
String _shortDay(String day) => day.length >= 10 ? day.substring(5) : day;

/// ISO "2026-09-01T10:00:00Z" → "10:00:00"; falls back on short payloads.
String _clock(String timestamp) =>
    timestamp.length >= 19 ? timestamp.substring(11, 19) : timestamp;
