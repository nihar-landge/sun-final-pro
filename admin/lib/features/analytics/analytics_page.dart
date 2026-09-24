import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_admin/core/theme.dart';
import 'package:feedback_admin/features/analytics/admin_analytics_bloc.dart';
import 'package:feedback_admin/features/users/admin_users_bloc.dart';

/// Analytics as a sidebar page — same data as the dashboard, deeper detail.
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminAnalyticsBloc, AdminAnalyticsState>(
      builder: (context, state) {
        if (state is AdminAnalyticsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdminAnalyticsFailure) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load analytics: ${state.message}'),
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
        final a = (state as AdminAnalyticsLoaded).analytics;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Analytics',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Citizen engagement and report-operations KPIs — every number is served live from the services.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text('CITIZEN ENGAGEMENT', style: _section(context)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _metric(context, '${a.pollStats.totalPolls}', 'Total polls'),
                    _metric(context, '${a.pollStats.totalVotes}', 'Total votes'),
                    _metric(context, '${a.feedbackStats.totalFeedback}',
                        'Reports submitted'),
                    _metric(context, '${a.feedbackStats.submittedLast7Days}',
                        'Last 7 days'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('REPORT OPERATIONS', style: _section(context)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DistributionBars(data: a.feedbackStats.byStatus),
              ),
            ),
            const SizedBox(height: 16),
            Text('ISSUE DISTRIBUTION', style: _section(context)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DistributionBars(data: a.feedbackStats.byCategory),
              ),
            ),
            const SizedBox(height: 16),
            Text('RESOLUTION', style: _section(context)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _metric(context,
                        '${a.feedbackStats.avgResolutionHours ?? '—'} h',
                        'Avg resolution time'),
                    _metric(context,
                        a.pollStats.topPollTitle != null
                            ? '${a.pollStats.topPollVotes}'
                            : '—',
                        'Top poll votes'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _metric(BuildContext context, String value, String label) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );

  TextStyle _section(BuildContext context) => Theme.of(context)
      .textTheme
      .labelSmall!
      .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Colors.blueGrey);
}

/// Users page extracted from the old tab content.
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminUsersBloc, AdminUsersState>(
      listener: (context, state) {
        final message = switch (state) {
          AdminUsersFailure s => s.message,
          AdminUsersMessage s => s.message,
          _ => null,
        };
        if (message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
      },
      child: const _UsersListView(),
    );
  }
}

class _UsersListView extends StatelessWidget {
  const _UsersListView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminUsersBloc, AdminUsersState>(
      builder: (context, state) {
        final users = switch (state) {
          AdminUsersLoaded s => s.users,
          AdminUsersMessage s => s.users,
          AdminUsersLoading s => s.users,
          AdminUsersFailure s => s.users,
        };
        final currentAdminId = switch (state) {
          AdminUsersLoaded s => s.currentAdminId,
          AdminUsersMessage s => s.currentAdminId,
          _ => 0,
        };
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Users',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                ),
                Expanded(
                  child: state is AdminUsersLoading && users.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: users.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final isSelf = user.id == currentAdminId;
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : '?'),
                                ),
                                title: Text(
                                    user.name.isEmpty ? '(no name)' : user.name),
                                subtitle: Text(user.phone),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    StatusChip(
                                        status: user.role, poll: false),
                                    const SizedBox(width: 4),
                                    if (!isSelf)
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (value) => context
                                            .read<AdminUsersBloc>()
                                            .add(AdminUserRoleChanged(
                                                userId: user.id,
                                                newRole: value)),
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                              value: 'CITIZEN',
                                              child: Text('Make Citizen')),
                                          PopupMenuItem(
                                              value: 'MODERATOR',
                                              child: Text('Make Moderator')),
                                          PopupMenuItem(
                                              value: 'ADMIN',
                                              child: Text('Make Admin')),
                                        ],
                                      )
                                    else
                                      const Tooltip(
                                        message:
                                            'You cannot change your own role',
                                        child: Icon(Icons.lock_outline,
                                            size: 18, color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
