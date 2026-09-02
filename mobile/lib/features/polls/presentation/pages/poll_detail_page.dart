import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'package:feedback_app/core/constants/api_constants.dart';
import 'package:feedback_app/features/polls/data/models/poll_model.dart';
import 'package:feedback_app/features/polls/domain/entities/poll.dart';
import 'package:feedback_app/features/polls/presentation/bloc/polls_bloc.dart';

/// Poll detail: vote when active, then watch the animated results update
/// in real time via the STOMP subscription on /topic/polls/{id}.
class PollDetailPage extends StatefulWidget {
  final int pollId;

  const PollDetailPage({super.key, required this.pollId});

  @override
  State<PollDetailPage> createState() => _PollDetailPageState();
}

class _PollDetailPageState extends State<PollDetailPage> {
  int? _selectedOption;
  bool _votedLocally = false; // guards against user-neutral WS frames
  StompClient? _stomp;
  StompUnsubscribe? _unsubscribe;

  @override
  void initState() {
    super.initState();
    context.read<PollsBloc>().add(PollResultsRefreshed(widget.pollId));
    _connectLive();
  }

  /// Live results: the STOMP endpoint rides the same gateway (ws://…/ws),
  /// so the phone and web builds both work through the existing tunnel.
  void _connectLive() {
    final wsUrl = ApiConstants.baseUrl.replaceFirst(RegExp(r'^http'), 'ws').replaceFirst(RegExp(r'/api/v1$'), '');
    _stomp = StompClient(
      config: StompConfig(
        url: wsUrl.endsWith('/') ? '${wsUrl}ws' : '$wsUrl/ws',
        onConnect: (StompFrame frame) {
          _unsubscribe = _stomp!.subscribe(
            destination: '/topic/polls/${widget.pollId}',
            callback: (StompFrame frame) {
              if (frame.body == null) return;
              try {
                final poll = PollModel.fromJson(
                    jsonDecode(frame.body!) as Map<String, dynamic>);
                if (mounted) {
                  context.read<PollsBloc>().add(PollLiveUpdate(poll));
                }
              } catch (_) {
                // Ignore malformed frames; the next vote re-broadcasts.
              }
            },
          );
        },
        onWebSocketError: (dynamic error) => debugPrint('WS error: $error'),
        onStompError: (StompFrame frame) => debugPrint('STOMP error: ${frame.body}'),
        // Reconnect with backoff so backgrounding the app recovers cleanly.
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _stomp!.activate();
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    _stomp?.deactivate();
    super.dispose();
  }

  void _vote() {
    if (_selectedOption == null) return;
    context.read<PollsBloc>().add(VoteRequested(pollId: widget.pollId, optionId: _selectedOption!));
    _selectedOption = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Poll')),
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
                  '${poll.totalVotes} votes · ${poll.status == 'ACTIVE' ? 'open until' : 'closed'} ${_fmt(poll.endTime)}${poll.anonymous ? ' · anonymous' : ''}',
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
                        : const Text('Cast vote'),
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
                          const Expanded(
                            child: Text(
                                'You already voted in this poll — thanks for participating!'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(poll.isActive ? 'Live results' : 'Results',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ...poll.options.map((option) => ResultBar(
                      result: option,
                      highlight: option.optionId == _selectedOption,
                    )),
                if (!poll.isActive) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () =>
                        context.read<PollsBloc>().add(PollResultsRefreshed(widget.pollId)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh results'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
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
          Text('LIVE',
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
              Text('${result.votes} votes',
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
