import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/l10n/entity_labels.dart';
import 'package:feedback_app/core/theme/status_colors.dart';
import 'package:feedback_app/l10n/gen/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.detailTitle)),
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
                    Text(l10n.detailCitizen,
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

                // ---- photos ----
                if (detail.images.isNotEmpty) ...[
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      itemCount: detail.images.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            detail.images[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, _, _) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: const Icon(Icons.broken_image_outlined,
                                  size: 40),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ---- upvote ----
                FilledButton.tonalIcon(
                  onPressed: busy ? null : () => context
                      .read<FeedbackDetailBloc>()
                      .add(const DetailUpvoteRequested()),
                  icon: const Icon(Icons.thumb_up_alt_rounded, size: 18),
                  label: Text(l10n.detailUpvoteSupport(item.upvotes)),
                ),
                const SizedBox(height: 16),

                // ---- official update (staff public note) ----
                if (detail.publicNote.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_user_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(l10n.detailOfficialUpdate,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        letterSpacing: 0.8,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(detail.publicNote),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ---- resolved celebration ----
                if (item.status == FeedbackStatus.resolved) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.detailResolvedTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text(
                          l10n.detailResolvedSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (detail.resolvedAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.detailResolvedDates(
                              _shortDate(item.createdAt),
                              _shortDate(detail.resolvedAt!.changedAt),
                              _duration(l10n, item.createdAt,
                                  detail.resolvedAt!.changedAt),
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        Text(
                          l10n.detailCitizensSupported(item.upvotes),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ---- timeline ----
                Text(l10n.detailProgress,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _Timeline(detail: detail),

                // ---- location ----
                if (item.latitude != null) ...[
                  const SizedBox(height: 20),
                  Text(l10n.detailLocation,
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
                Text(l10n.detailComments(detail.comments.length),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (detail.comments.isEmpty)
                  Text(l10n.detailNoComments,
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

  String _shortDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '—';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _duration(AppLocalizations l10n, String fromIso, String toIso) {
    final from = DateTime.tryParse(fromIso);
    final to = DateTime.tryParse(toIso);
    if (from == null || to == null) return '';
    final days = to.difference(from).inDays;
    if (days < 1) return l10n.detailSameDay;
    return l10n.detailDaysCount(days);
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
    final l10n = AppLocalizations.of(context);
    final steps = <_TimelineStep>[
      _TimelineStep(
          label: l10n.detailTimelineSubmitted,
          time: detail.item.createdAt,
          done: true,
          color: Theme.of(context).colorScheme.primary),
      for (final change in detail.history)
        _TimelineStep(
          label: feedbackStatusLabel(context, change.newStatus),
          time: change.changedAt,
          done: true,
          current: change == detail.history.last &&
              change.newStatus != 'RESOLVED',
          color: StatusColors.forStatus(change.newStatus),
        ),
      if (detail.item.status != FeedbackStatus.resolved)
        _TimelineStep(
          label: detail.item.status == FeedbackStatus.inReview
              ? l10n.detailTimelineResolution
              : l10n.detailTimelineReview,
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
            Text(
                AppLocalizations.of(context)
                    .detailCitizenNumber('${comment.userId}'),
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
            decoration: InputDecoration(
                hintText: AppLocalizations.of(context).detailCommentHint),
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
