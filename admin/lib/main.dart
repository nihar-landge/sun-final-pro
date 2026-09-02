import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_admin/core/api_client.dart';
import 'package:feedback_admin/features/analytics/admin_analytics_bloc.dart';
import 'package:feedback_admin/features/auth/admin_auth_bloc.dart';
import 'package:feedback_admin/features/feedback/admin_feedback_bloc.dart';
import 'package:feedback_admin/features/polls/admin_polls_bloc.dart';
import 'package:feedback_admin/features/users/admin_users_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FeedbackAdminApp());
}

class FeedbackAdminApp extends StatelessWidget {
  const FeedbackAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = AdminApiClient();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AdminAuthBloc(apiClient: apiClient)),
        BlocProvider(create: (_) => AdminPollsBloc(apiClient: apiClient)),
        BlocProvider(create: (_) => AdminFeedbackBloc(apiClient: apiClient)),
        BlocProvider(create: (_) => AdminAnalyticsBloc(apiClient: apiClient)),
        BlocProvider(create: (_) => AdminUsersBloc(apiClient: apiClient)),
      ],
      child: MaterialApp(
        title: 'Civic Feedback — Admin',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF283593)),
        ),
        home: const AdminGate(),
      ),
    );
  }
}

/// Starts at the login screen; after authentication shows the dashboard.
class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminAuthBloc, AdminAuthState>(
      listener: (context, state) {
        if (state is AdminAuthFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is AdminAuthenticated) {
          context.read<AdminUsersBloc>().setCurrentAdminId(state.userId);
          context.read<AdminUsersBloc>().add(const AdminUsersSearched());
        }
      },
      builder: (context, state) {
        if (state is AdminAuthenticated) return const AdminDashboardPage();
        return const AdminLoginPage();
      },
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _phoneController = TextEditingController(text: '9999999999');
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: BlocBuilder<AdminAuthBloc, AdminAuthState>(
          builder: (context, state) {
            if (state is AdminAuthLoading) {
              return const CircularProgressIndicator();
            }
            if (state is AdminAccessDenied) {
              return const _DeniedCard();
            }
            final otpSent = state is AdminOtpSent;
            return _LoginCard(
              phoneController: _phoneController,
              otpController: _otpController,
              otpSent: otpSent,
              sentPhone: otpSent ? state.phone : null,
            );
          },
        ),
      ),
    );
  }
}

class _DeniedCard extends StatelessWidget {
  const _DeniedCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('This account does not have admin access.'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  context.read<AdminAuthBloc>().add(AdminLogoutRequested()),
              child: const Text('Try another account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final bool otpSent;
  final String? sentPhone;

  const _LoginCard({
    required this.phoneController,
    required this.otpController,
    required this.otpSent,
    this.sentPhone,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Admin Sign in',
                  style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('Public Feedback & Polling System',
                  style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              if (!otpSent) ...[
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Admin phone number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context
                      .read<AdminAuthBloc>()
                      .add(AdminOtpSendRequested(phoneController.text.trim())),
                  child: const Text('Send OTP'),
                ),
              ] else ...[
                Text('Code sent to $sentPhone', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextField(
                  controller: otpController,
                  decoration: const InputDecoration(labelText: '6-digit OTP'),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.read<AdminAuthBloc>().add(
                        AdminOtpVerifyRequested(
                          phone: sentPhone!,
                          code: otpController.text.trim(),
                        ),
                      ),
                  child: const Text('Sign in'),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Dev: OTP is printed in the auth-service log (dev echo)',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AdminAuthBloc>().add(AdminLogoutRequested());
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AdminGate()),
                  (_) => false,
                );
              },
            ),
          ],
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(icon: Icon(Icons.poll), text: 'Polls'),
            Tab(icon: Icon(Icons.campaign), text: 'Feedback'),
            Tab(icon: Icon(Icons.insights), text: 'Analytics'),
            Tab(icon: Icon(Icons.manage_accounts), text: 'Users'),
          ]),
        ),
        body: const TabBarView(
          children: [
            _PollsTab(),
            _FeedbackTab(),
            _AnalyticsTab(),
            _UsersTab(),
          ],
        ),
      ),
    );
  }
}

class _PollsTab extends StatelessWidget {
  const _PollsTab();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminPollsBloc, AdminPollsState>(
      listener: (context, state) {
        if (state is AdminPollsFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is AdminPollsMessage) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final polls = switch (state) {
          AdminPollsLoaded s => s.polls,
          AdminPollsMessage s => s.polls,
          _ => const <AdminPoll>[],
        };
        if (state is AdminPollsLoading && polls.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Stack(
          children: [
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: polls.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final poll = polls[index];
                return ListTile(
                  tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  title: Text(poll.title),
                  subtitle: Text('${poll.status} · ${poll.totalVotes} votes'),
                  trailing: poll.status == 'ACTIVE'
                      ? TextButton(
                          onPressed: () => context
                              .read<AdminPollsBloc>()
                              .add(AdminPollClosed(poll.id)),
                          child: const Text('Close'))
                      : null,
                );
              },
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                icon: const Icon(Icons.add),
                label: const Text('New poll'),
                onPressed: () => _showCreateDialog(context),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final options = <TextEditingController>[
      TextEditingController(),
      TextEditingController(),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 20, right: 20, top: 20),
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create poll', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(controller: titleController,
                  decoration: const InputDecoration(labelText: 'Question / title')),
              const SizedBox(height: 10),
              TextField(controller: descController,
                  decoration: const InputDecoration(labelText: 'Description (optional)')),
              const SizedBox(height: 10),
              ...options.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: entry.value,
                            decoration: InputDecoration(
                                labelText: 'Option ${entry.key + 1}'),
                          ),
                        ),
                        if (options.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () =>
                                setSheetState(() => options.removeAt(entry.key)),
                          ),
                      ],
                    ),
                  )),
              TextButton.icon(
                onPressed: () => setSheetState(() => options.add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: const Text('Add option'),
              ),
              FilledButton(
                onPressed: () {
                  final texts =
                      options.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                  if (titleController.text.trim().isEmpty || texts.length < 2) return;
                  context.read<AdminPollsBloc>().add(AdminPollCreated(
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        options: texts,
                      ));
                  Navigator.of(sheetContext).pop();
                },
                child: const Text('Publish poll'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminFeedbackBloc, AdminFeedbackState>(
      listener: (context, state) {
        if (state is AdminFeedbackFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is AdminFeedbackMessage) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final items = switch (state) {
          AdminFeedbackLoaded s => s.items,
          AdminFeedbackMessage s => s.items,
          _ => const <AdminFeedback>[],
        };
        if (state is AdminFeedbackLoading && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: true,
                    onSelected: (_) => context
                        .read<AdminFeedbackBloc>()
                        .add(const AdminFeedbackRefreshed()),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Open'),
                    selected: false,
                    onSelected: (_) => context
                        .read<AdminFeedbackBloc>()
                        .add(const AdminFeedbackRefreshed(status: 'OPEN')),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('In review'),
                    selected: false,
                    onSelected: (_) => context
                        .read<AdminFeedbackBloc>()
                        .add(const AdminFeedbackRefreshed(status: 'IN_REVIEW')),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    tileColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    title: Text(item.title),
                    subtitle: Text(
                        '${item.category} · ${item.status} · ${item.upvotes} upvotes\n${item.description}',
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) => context
                          .read<AdminFeedbackBloc>()
                          .add(AdminFeedbackStatusChanged(
                              feedbackId: item.id, newStatus: value)),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'IN_REVIEW', child: Text('Mark in review')),
                        PopupMenuItem(value: 'RESOLVED', child: Text('Mark resolved')),
                        PopupMenuItem(value: 'OPEN', child: Text('Re-open')),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Analytics tab: KPI cards, distributions and the live event feed.
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminAnalyticsBloc, AdminAnalyticsState>(
      listener: (context, state) {
        if (state is AdminAnalyticsFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
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
        final analytics = (state as AdminAnalyticsLoaded).analytics;
        return RefreshIndicator(
          onRefresh: () async => context
              .read<AdminAnalyticsBloc>()
              .add(const AdminAnalyticsRefreshed()),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Participation', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  _KpiCard(
                      label: 'Total polls', value: '${analytics.pollStats.totalPolls}'),
                  const SizedBox(width: 10),
                  _KpiCard(
                      label: 'Active now', value: '${analytics.pollStats.activePolls}'),
                  const SizedBox(width: 10),
                  _KpiCard(
                      label: 'Total votes',
                      value: '${analytics.pollStats.totalVotes}'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Avg ${analytics.pollStats.avgVotesPerPoll} votes/poll'
                '${analytics.pollStats.topPollTitle != null ? ' · top: ${analytics.pollStats.topPollTitle} (${analytics.pollStats.topPollVotes})' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Text('Feedback status', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _DistributionBars(
                  data: analytics.feedbackStats.byStatus,
                  colors: const {
                    'OPEN': Colors.orange,
                    'IN_REVIEW': Colors.indigo,
                    'RESOLVED': Colors.green,
                  }),
              const SizedBox(height: 20),
              Text('Feedback by category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _DistributionBars(data: analytics.feedbackStats.byCategory),
              const SizedBox(height: 8),
              Text(
                '${analytics.feedbackStats.totalFeedback} reports · ${analytics.feedbackStats.submittedLast7Days} in last 7 days'
                ' · avg resolution ${analytics.feedbackStats.avgResolutionHours ?? '—'} h',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Text('Live event feed (RabbitMQ)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (analytics.events.isEmpty)
                const Text('No events consumed yet.')
              else
                ...analytics.events.take(15).map((event) => ListTile(
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
                      trailing: Text(
                        event.occurredAt.substring(11, 19),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;

  const _KpiCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple horizontal distribution bars (no chart dependency needed).
class _DistributionBars extends StatelessWidget {
  final Map<String, int> data;
  final Map<String, Color> colors;

  const _DistributionBars({required this.data, this.colors = const {}});

  @override
  Widget build(BuildContext context) {
    final max = data.values.fold<int>(1, (m, v) => v > m ? v : m);
    final total = data.values.fold<int>(0, (s, v) => s + v);
    return Column(
      children: data.entries.map((entry) {
        final color = colors[entry.key] ?? Theme.of(context).colorScheme.primary;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(entry.key, style: Theme.of(context).textTheme.bodySmall),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: entry.value / max,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  total == 0 ? '0' : '${entry.value} (${(entry.value * 100 / total).round()}%)',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// User management tab: search citizens, promote/demote roles.
/// An admin cannot change their own role (server-enforced and hidden in UI).
class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => __UsersTabState();
}

class __UsersTabState extends State<_UsersTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String? role) {
    context.read<AdminUsersBloc>().add(AdminUsersSearched(
          search: _searchController.text,
          role: role,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminUsersBloc, AdminUsersState>(
      listener: (context, state) {
        if (state is AdminUsersFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is AdminUsersMessage) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
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
        final activeRole = switch (state) {
          AdminUsersLoaded s => s.role,
          AdminUsersMessage s => s.role,
          AdminUsersLoading s => s.role,
          AdminUsersFailure s => s.role,
        };

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or phone',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => _search(activeRole),
                  ),
                ),
                onSubmitted: (_) => _search(activeRole),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: activeRole == null,
                    onSelected: (_) => _search(null),
                  ),
                  const SizedBox(width: 8),
                  for (final role in const ['CITIZEN', 'MODERATOR', 'ADMIN']) ...[
                    ChoiceChip(
                      label: Text(role.substring(0, 1) + role.substring(1).toLowerCase()),
                      selected: activeRole == role,
                      onSelected: (_) => _search(role),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Expanded(
              child: state is AdminUsersLoading && users.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                      ? const Center(child: Text('No users match.'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: users.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final isSelf = user.id == currentAdminId;
                            return ListTile(
                              tileColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              leading: CircleAvatar(
                                child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(fontSize: 16)),
                              ),
                              title: Text(user.name.isEmpty ? '(no name)' : user.name),
                              subtitle: Text(user.phone),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _RoleChip(role: user.role),
                                  if (!isSelf)
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (value) => context
                                          .read<AdminUsersBloc>()
                                          .add(AdminUserRoleChanged(
                                              userId: user.id, newRole: value)),
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                            value: 'CITIZEN', child: Text('Make Citizen')),
                                        PopupMenuItem(
                                            value: 'MODERATOR',
                                            child: Text('Make Moderator')),
                                        PopupMenuItem(
                                            value: 'ADMIN', child: Text('Make Admin')),
                                      ],
                                    )
                                  else
                                    const Tooltip(
                                      message: 'You cannot change your own role',
                                      child: Icon(Icons.lock_outline,
                                          size: 18, color: Colors.grey),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'ADMIN' => Colors.deepPurple,
      'MODERATOR' => Colors.indigo,
      _ => Colors.blueGrey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(role,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
