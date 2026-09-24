import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/constants/app_constants.dart';
import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';
import 'package:feedback_app/features/feedback/presentation/bloc/feedback_bloc.dart';
import 'package:feedback_app/features/feedback/presentation/pages/feedback_detail_page.dart';
import 'package:feedback_app/features/map/presentation/pages/nearby_issues_map_page.dart';
import 'package:feedback_app/features/polls/domain/entities/poll.dart';
import 'package:feedback_app/features/polls/presentation/bloc/polls_bloc.dart';
import 'package:feedback_app/features/polls/presentation/pages/poll_detail_page.dart';
import 'package:feedback_app/shared/widgets/cards.dart';
import 'package:feedback_app/shared/widgets/states.dart';

/// Home — the civic dashboard: greeting, featured poll, quick actions,
/// nearby issues and the citizen's own activity.
class HomePage extends StatefulWidget {
  final void Function(int tabIndex)? onNavigate;

  const HomePage({super.key, this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void initState() {
    super.initState();
    // Refresh everything the dashboard shows.
    context.read<PollsBloc>().add(const PollsRequested(status: 'active'));
    context.read<FeedbackBloc>().add(const NearbyFeedbackRequested(lat: 18.5204, lng: 73.8567));
    context.read<FeedbackBloc>().add(const MyReportsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<PollsBloc>().add(const PollsRequested(status: 'active'));
          context.read<FeedbackBloc>().add(const NearbyFeedbackRequested(lat: 18.5204, lng: 73.8567));
          context.read<FeedbackBloc>().add(const MyReportsRequested());
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_greeting 👋',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('Make your city better.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => widget.onNavigate?.call(3),
                  icon: const Icon(Icons.notifications_outlined),
                ),
              ],
            ),
            // ---- Featured active poll ----
            BlocBuilder<PollsBloc, PollsState>(
              builder: (context, state) {
                final polls = switch (state) {
                  PollsLoaded s => s.polls,
                  PollVoting s => s.polls,
                  VoteRecorded s => s.polls,
                  PollsFailure s => s.polls,
                  _ => const <Poll>[],
                };
                if (polls.isEmpty) return const SizedBox.shrink();
                final featured = polls.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Active poll',
                      actionLabel: 'See all',
                      onAction: () => widget.onNavigate?.call(1),
                    ),
                    PollCard(
                      poll: featured,
                      hasVoted: featured.hasVoted ||
                          (state is VoteRecorded && state.poll.id == featured.id),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PollDetailPage(pollId: featured.id),
                      )),
                    ),
                  ],
                );
              },
            ),
            // ---- Quick actions ----
            SectionHeader(title: 'Quick actions'),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_a_photo_outlined,
                    label: 'Report\nIssue',
                    onTap: () => widget.onNavigate?.call(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.map_outlined,
                    label: 'Nearby\nIssues',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const NearbyIssuesMapPage(),
                    )),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.how_to_vote_outlined,
                    label: 'Active\nPolls',
                    onTap: () => widget.onNavigate?.call(1),
                  ),
                ),
              ],
            ),
            // ---- Nearby issues ----
            BlocBuilder<FeedbackBloc, FeedbackState>(
              buildWhen: (prev, cur) =>
                  cur is FeedbackLoaded && cur.nearby ||
                  cur is FeedbackLoading ||
                  (cur is FeedbackFailure),
              builder: (context, state) {
                final items = switch (state) {
                  FeedbackLoaded s when s.nearby => s.items,
                  _ => const <FeedbackItem>[],
                };
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title: 'Nearby issues'),
                    if (state is FeedbackLoading && items.isEmpty)
                      const LoadingSkeleton(cards: 2)
                    else if (items.isEmpty)
                      const EmptyState(
                        icon: Icons.explore_outlined,
                        title: 'No nearby reports',
                        subtitle: 'Your area looks clean — or be the first to report.',
                      )
                    else
                      ...items.take(3).map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ReportCard(
                              item: item,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FeedbackDetailPage(feedbackId: item.id),
                                ),
                              ),
                              onUpvote: () => context
                                  .read<FeedbackBloc>()
                                  .add(UpvoteRequested(item.id)),
                            ),
                          )),
                  ],
                );
              },
            ),
            // ---- My activity ----
            BlocBuilder<FeedbackBloc, FeedbackState>(
              buildWhen: (prev, cur) =>
                  cur is FeedbackLoaded && cur.mine ||
                  cur is FeedbackLoading ||
                  (cur is FeedbackFailure),
              builder: (context, state) {
                final items = switch (state) {
                  FeedbackLoaded s when s.mine => s.items,
                  _ => const <FeedbackItem>[],
                };
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title: 'Your reports'),
                    if (items.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.campaign_outlined,
                                  color: scheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "You haven't reported anything yet.\nSpotted a problem? Tap + to report it.",
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...items.take(3).map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ReportCard(
                              item: item,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FeedbackDetailPage(feedbackId: item.id),
                                ),
                              ),
                            ),
                          )),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(AppConstants.appTagline,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.outline)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: scheme.primary),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

