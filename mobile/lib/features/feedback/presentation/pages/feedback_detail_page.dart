import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/theme/status_colors.dart';
import 'package:feedback_app/features/feedback/data/repositories/feedback_repository_impl.dart';
import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';
import 'package:feedback_app/features/feedback/presentation/bloc/feedback_detail_bloc.dart';
import 'package:feedback_app/features/map/presentation/widgets/mini_map_view.dart';
import 'package:feedback_app/shared/widgets/status_chips.dart';

/// Report detail — status, upvotes, progress timeline, comments and
/// a map preview. Deep-link target from Home, Alerts and the wizard.
class FeedbackDetailPage extends StatelessWidget {
  final int feedbackId;

  const FeedbackDetailPage({super.key, required this.feedbackId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FeedbackDetailBloc(
        repository: context.read<FeedbackRepositoryImpl>(),
        feedbackId: feedbackId,
      )..add(DetailLoaded(feedbackId)),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: BlocConsumer<FeedbackDetailBloc, DetailState>(
        listener: (context, state) {
          if (state is DetailMessage) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is DetailFailure && state.detail == null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final detail = switch (state) {
            DetailReady s => s.detail,
            DetailActionInProgress s => s.detail,
            DetailMessage s => s.detail,
            DetailFailure s => s.detail,
            _ => null,
          };
          if (detail == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final busy = state is DetailActionInProgress;
          final item = detail.item;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ---- header ----
                Row(
                  children: [
                    StatusChip(status: item.status.name, filled: true),
                    const Spacer(),
                    Text('#${item.id}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 12),
                Text(item.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(item.description,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(width: 4),
                    Text('Citizen',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule,
                        size: 16, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(_fmtDate(item.createdAt),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 16),

                // ---- upvote ----
                FilledButton.tonalIcon(
                  onPressed: busy ? null : () => context
                      .read<FeedbackDetailBloc>()
                      .add(const DetailUpvoteRequested()),
                  icon: const Icon(Icons.thumb_up_alt_rounded, size: 18),
                  label: Text(
                      '${item.upvotes} ${item.upvotes == 1 ? 'person supports' : 'people support'} this'),
                ),
                const SizedBox(height: 16),

                // ---- timeline ----
                Text('Progress',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _Timeline(detail: detail),

                // ---- location ----
                if (item.latitude != null) ...[
                  const SizedBox(height: 20),
                  Text('Location',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: MiniMapView(
                        latitude: item.latitude!, longitude: item.longitude!),
                  ),
                ],

                // ---- comments ----
                const SizedBox(height: 20),
                Text('Comments (${detail.comments.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (detail.comments.isEmpty)
                  Text('No comments yet — start the conversation.',
                      style: Theme.of(context).textTheme.bodySmall)
                else
                  ...detail.comments.map((comment) => _CommentBubble(
                        comment: comment,
                        isMine: comment.userId == item.userId,
                      )),
                const SizedBox(height: 8),
                const _CommentComposer(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmtDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

/// Vertical progress timeline derived from the audited status history.
class _Timeline extends StatelessWidget {
  final FeedbackDetail detail;

  const _Timeline({required this.detail});

  @override
  Widget build(BuildContext context) {
    final steps = <_TimelineStep>[
      _TimelineStep(
          label: 'Report submitted',
          time: detail.item.createdAt,
          done: true,
          color: Theme.of(context).colorScheme.primary),
      for (final change in detail.history)
        _TimelineStep(
          label: StatusColors.label(change.newStatus),
          time: change.changedAt,
          done: true,
          current: change == detail.history.last &&
              change.newStatus != 'RESOLVED',
          color: StatusColors.forStatus(change.newStatus),
        ),
      if (detail.item.status != FeedbackStatus.resolved)
        _TimelineStep(
          label: detail.item.status == FeedbackStatus.inReview
              ? 'Resolution'
              : 'Review',
          time: null,
          done: false,
          color: Theme.of(context).colorScheme.outline,
        ),
    ];

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(
            step: steps[i],
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _TimelineStep {
  final String label;
  final String? time;
  final bool done;
  final bool current;
  final Color color;

  _TimelineStep({
    required this.label,
    required this.time,
    required this.done,
    required this.color,
    this.current = false,
  });
}

class _TimelineRow extends StatelessWidget {
  final _TimelineStep step;
  final bool isLast;

  const _TimelineRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.done ? step.color : scheme.surface,
                  border: Border.all(
                      color: step.done ? step.color : scheme.outlineVariant,
                      width: 2),
                ),
                child: step.done
                    ? Icon(Icons.check,
                        size: 14, color: step.current ? step.color : Colors.white)
                    : const SizedBox.shrink(),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: step.done ? step.color : scheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.label,
                      style: TextStyle(
                          fontWeight:
                              step.current || step.done ? FontWeight.w700 : FontWeight.w500)),
                  if (step.time != null)
                    Text(_fmt(step.time!),
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    final local = date.toLocal();
    return '${local.day}/${local.month} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _CommentBubble extends StatelessWidget {
  final dynamic comment;
  final bool isMine;

  const _CommentBubble({required this.comment, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isMine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMine ? 14 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Citizen #${comment.userId}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(comment.text),
          ],
        ),
      ),
    );
  }
}

class _CommentComposer extends StatefulWidget {
  const _CommentComposer();

  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<FeedbackDetailBloc>().add(DetailCommentSubmitted(text));
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration:
                const InputDecoration(hintText: 'Write a comment…'),
            onSubmitted: (_) => _send(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _send,
          icon: const Icon(Icons.send_rounded),
        ),
      ],
    );
  }
}
