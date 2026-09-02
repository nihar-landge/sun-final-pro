import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/features/polls/domain/entities/poll.dart';
import 'package:feedback_app/features/polls/presentation/bloc/polls_bloc.dart';
import 'package:feedback_app/features/polls/presentation/pages/poll_detail_page.dart';

/// Live polls list — real data from poll-service via the gateway.
class PollsListPage extends StatelessWidget {
  const PollsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Polls')),
      body: BlocConsumer<PollsBloc, PollsState>(
        listener: (context, state) {
          if (state is PollsFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is PollsLoading || state is PollsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          // Every state after a load carries the list snapshot, so voting or
          // an error never blanks the screen.
          final polls = switch (state) {
            PollsLoaded s => s.polls,
            PollVoting s => s.polls,
            VoteRecorded s => s.polls,
            PollsFailure s => s.polls,
            _ => const <Poll>[],
          };
          if (polls.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => context.read<PollsBloc>().add(const PollsRequested()),
              child: const Center(child: Text('No active polls right now.\nPull to refresh.', textAlign: TextAlign.center)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => context.read<PollsBloc>().add(const PollsRequested()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: polls.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final poll = polls[index];
                return _PollCard(
                  poll: poll,
                  busy: state is PollVoting,
                  hasVoted: poll.hasVoted ||
                      (state is VoteRecorded && state.poll.id == poll.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  final Poll poll;
  final bool busy;
  final bool hasVoted;

  const _PollCard({required this.poll, required this.busy, this.hasVoted = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PollDetailPage(pollId: poll.id),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusChip(status: poll.status),
                  if (hasVoted) ...[
                    const SizedBox(width: 6),
                    _VotedChip(),
                  ],
                  const Spacer(),
                  Text('${poll.totalVotes} votes',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 10),
              Text(poll.title, style: Theme.of(context).textTheme.titleMedium),
              if (poll.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(poll.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.how_to_vote_outlined,
                      size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${poll.options.isEmpty ? "Tap to view" : "${poll.options.length} options"} · ends ${_format(poll.endTime)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _format(DateTime time) {
    final local = time.toLocal();
    return '${local.day}/${local.month}';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, label) = switch (status) {
      'ACTIVE' => (scheme.primary, 'LIVE'),
      'SCHEDULED' => (scheme.tertiary, 'SOON'),
      _ => (scheme.outline, 'CLOSED'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _VotedChip extends StatelessWidget {
  const _VotedChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('VOTED',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: scheme.secondary)),
    );
  }
}
