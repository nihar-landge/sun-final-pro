import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/l10n/gen/app_localizations.dart';
import 'package:feedback_app/features/polls/domain/entities/poll.dart';
import 'package:feedback_app/features/polls/presentation/bloc/polls_bloc.dart';

/// Poll detail: vote when active, then refresh the animated results on a
/// 5-second timer (plain REST polling — no WebSocket needed).
class PollDetailPage extends StatefulWidget {
  final int pollId;

  const PollDetailPage({super.key, required this.pollId});

  @override
  State<PollDetailPage> createState() => _PollDetailPageState();
}

class _PollDetailPageState extends State<PollDetailPage> {
  int? _selectedOption;
  bool _votedLocally = false; // covers the window before results refresh
  Timer? _resultsTimer;

  @override
  void initState() {
    super.initState();
    context.read<PollsBloc>().add(PollResultsRefreshed(widget.pollId));
    _resultsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        context.read<PollsBloc>().add(PollResultsRefreshed(widget.pollId));
      }
    });
  }

  @override
  void dispose() {
    _resultsTimer?.cancel();
    super.dispose();
  }

  void _vote() {
    if (_selectedOption == null) return;
    context.read<PollsBloc>().add(VoteRequested(pollId: widget.pollId, optionId: _selectedOption!));
    _selectedOption = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pollDetailTitle)),
      body: BlocConsumer<PollsBloc, PollsState>(
        listener: (context, state) {
          if (state is PollsFailure) {
            if (state.message.toLowerCase().contains('already voted')) {
              setState(() => _votedLocally = true);
            }
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is VoteRecorded && state.poll.hasVoted) {
            _votedLocally = true;
          }
        },
        builder: (context, state) {
          final Poll? poll = state is VoteRecorded ? state.poll : null;
          if (poll == null || poll.id != widget.pollId) {
            return const Center(child: CircularProgressIndicator());
          }
          final voting = state is PollVoting;
          final voted = poll.hasVoted || _votedLocally;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    if (poll.isActive)
                      const _LiveBadge(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(poll.title, style: Theme.of(context).textTheme.headlineSmall),
                    ),
                  ],
                ),
                if (poll.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(poll.description, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 8),
                Text(
                  '${l10n.pollVotesCount(poll.totalVotes)} · ${poll.status == 'ACTIVE' ? l10n.pollOpenUntil : l10n.pollClosedLabel} ${_fmt(poll.endTime)}${poll.anonymous ? l10n.pollAnonymousSuffix : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                if (poll.isActive && !voted) ...[
                  RadioGroup<int>(
                    groupValue: _selectedOption,
                    onChanged: (v) {
                      if (!voting) setState(() => _selectedOption = v);
                    },
                    child: Column(
                      children: poll.options
                          .map((option) => RadioListTile<int>(
                                value: option.optionId,
                                title: Text(option.text),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: (_selectedOption == null || voting) ? null : _vote,
                    child: voting
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.pollCastVote),
                  ),
                  const SizedBox(height: 24),
                ] else if (voted) ...[
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(l10n.pollAlreadyVoted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(poll.isActive ? l10n.pollLiveResults : l10n.pollResults,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ...poll.options.map((option) => ResultBar(
                      result: option,
                      highlight: option.optionId == _selectedOption,
                    )),

                // ---- poll insights ----
                if (poll.options.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(l10n.pollInsights,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trending_up, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(l10n.pollTopChoice,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall)),
                              Text(_topChoice(poll),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.groups_outlined, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(l10n.pollParticipation,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall)),
                              Text(l10n.pollCitizensCount(poll.totalVotes),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(l10n.pollEnds,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall)),
                              Text(_endsLabel(l10n, poll),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (!poll.isActive) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () =>
                        context.read<PollsBloc>().add(PollResultsRefreshed(widget.pollId)),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.pollRefreshResults),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _topChoice(Poll poll) {
    if (poll.options.isEmpty) return '—';
    final top = poll.options.reduce((a, b) => a.percentage >= b.percentage ? a : b);
    return top.text;
  }

  String _endsLabel(AppLocalizations l10n, Poll poll) {
    final diff = poll.endTime.difference(DateTime.now());
    if (diff.isNegative) return l10n.pollEnded;
    if (diff.inDays >= 1) {
      return l10n.pollEndsInDaysHours(diff.inDays, diff.inHours % 24);
    }
    if (diff.inHours >= 1) return l10n.pollEndsInHours(diff.inHours);
    return l10n.pollEndsInMinutes(diff.inMinutes);
  }

  String _fmt(DateTime time) {
    final local = time.toLocal();
    return '${local.day}/${local.month} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: scheme.primary),
          const SizedBox(width: 4),
          Text(AppLocalizations.of(context).pollStatusLive,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: scheme.primary)),
        ],
      ),
    );
  }
}

/// Animated result bar in the blueprint's style.
class ResultBar extends StatelessWidget {
  final PollOptionResult result;
  final bool highlight;

  const ResultBar({super.key, required this.result, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  result.text,
                  style: TextStyle(
                    fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                    color: highlight ? scheme.primary : null,
                  ),
                ),
              ),
              Text(
                  AppLocalizations.of(context).pollVotesCount(result.votes),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: result.percentage / 100,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.primary.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${result.percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
