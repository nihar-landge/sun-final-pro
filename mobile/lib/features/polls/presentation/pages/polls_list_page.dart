import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/features/polls/domain/entities/poll.dart';
import 'package:feedback_app/features/polls/presentation/bloc/polls_bloc.dart';
import 'package:feedback_app/features/polls/presentation/pages/poll_detail_page.dart';
import 'package:feedback_app/shared/widgets/cards.dart';
import 'package:feedback_app/shared/widgets/states.dart';

/// Polls tab — Active / Upcoming / Closed segments over the real API.
class PollsListPage extends StatefulWidget {
  const PollsListPage({super.key});

  @override
  State<PollsListPage> createState() => _PollsListPageState();
}

class _PollsListPageState extends State<PollsListPage> {
  int _segment = 0;
  static const _statuses = ['active', 'scheduled', 'closed'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<PollsBloc>().add(PollsRequested(status: _statuses[_segment]));
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
              child: Text('Polls',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Active')),
                ButtonSegment(value: 1, label: Text('Upcoming')),
                ButtonSegment(value: 2, label: Text('Closed')),
              ],
              selected: {_segment},
              onSelectionChanged: (selection) {
                setState(() => _segment = selection.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: BlocConsumer<PollsBloc, PollsState>(
              listener: (context, state) {
                if (state is PollsFailure) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is PollsLoading) {
                  return const LoadingSkeleton();
                }
                final polls = switch (state) {
                  PollsLoaded s => s.polls,
                  PollVoting s => s.polls,
                  VoteRecorded s => s.polls,
                  PollsFailure s => s.polls,
                  _ => const <Poll>[],
                };
                if (state is PollsFailure && polls.isEmpty) {
                  return ErrorState(message: state.message, onRetry: _load);
                }
                if (polls.isEmpty) {
                  return EmptyState(
                    icon: _emptyIcon,
                    title: _emptyTitle,
                    subtitle: 'Pull down to refresh.',
                    actionLabel: 'Refresh',
                    onAction: _load,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: polls.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final poll = polls[index];
                      return PollCard(
                        poll: poll,
                        hasVoted: poll.hasVoted ||
                            (state is VoteRecorded && state.poll.id == poll.id),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => PollDetailPage(pollId: poll.id)),
                        ),
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

  IconData get _emptyIcon => switch (_segment) {
        0 => Icons.how_to_vote_outlined,
        1 => Icons.schedule,
        _ => Icons.inventory_2_outlined,
      };

  String get _emptyTitle => switch (_segment) {
        0 => 'No active polls right now',
        1 => 'No upcoming polls scheduled',
        _ => 'No closed polls yet',
      };
}
