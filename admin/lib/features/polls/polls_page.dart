import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_admin/core/theme.dart';
import 'package:feedback_admin/features/polls/admin_polls_bloc.dart';

/// Poll administration: builder with scheduling and dynamic options,
/// duplicate-for-reuse, close, and result bars.
class PollsPage extends StatelessWidget {
  const PollsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PollsView();
  }
}

class _PollsView extends StatelessWidget {
  const _PollsView();

  void _openBuilder(BuildContext context, {AdminPoll? duplicate}) {
    final titleController =
        TextEditingController(text: duplicate?.title ?? '');
    final descController = TextEditingController();
    final options = <TextEditingController>[
      if (duplicate == null)
        TextEditingController()
      else
        for (final option in duplicate.results)
          TextEditingController(text: option.text),
      if (duplicate != null) ...[
        TextEditingController(),
        TextEditingController(),
      ],
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(duplicate == null ? 'Create poll' : 'Duplicate poll',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Question / title')),
              const SizedBox(height: 10),
              TextField(
                  controller: descController,
                  decoration:
                      const InputDecoration(labelText: 'Description (optional)')),
              const SizedBox(height: 12),
              Text('OPTIONS', style: _label(sheetContext)),
              ...options.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: entry.value,
                            decoration:
                                InputDecoration(labelText: 'Option ${entry.key + 1}'),
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
                onPressed: () =>
                    setSheetState(() => options.add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: const Text('Add option'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final texts = options
                      .map((c) => c.text.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();
                  if (titleController.text.trim().isEmpty || texts.length < 2) {
                    return;
                  }
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminPollsBloc, AdminPollsState>(
      listener: (context, state) {
        final message = switch (state) {
          AdminPollsFailure s => s.message,
          AdminPollsMessage s => s.message,
          _ => null,
        };
        if (message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final polls = switch (state) {
          AdminPollsLoaded s => s.polls,
          AdminPollsMessage s => s.polls,
          _ => const <AdminPoll>[],
        };
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Polls',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                if (state is AdminPollsLoading && polls.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (polls.isEmpty)
                  const Card(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No polls yet — create the first one.')))
                else
                  ...polls.map((poll) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PollRow(
                          poll: poll,
                          onDuplicate: () => _openBuilder(context, duplicate: poll),
                        ),
                      )),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                heroTag: 'new-poll',
                icon: const Icon(Icons.add),
                label: const Text('New poll'),
                onPressed: () => _openBuilder(context),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PollRow extends StatelessWidget {
  final AdminPoll poll;
  final VoidCallback onDuplicate;

  const _PollRow({required this.poll, required this.onDuplicate});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip(status: poll.status, poll: true),
                const Spacer(),
                Text('${poll.totalVotes} votes',
                    style: Theme.of(context).textTheme.bodySmall),
                IconButton(
                  tooltip: 'Duplicate',
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: onDuplicate,
                ),
                if (poll.status == 'ACTIVE')
                  TextButton(
                    onPressed: () =>
                        context.read<AdminPollsBloc>().add(AdminPollClosed(poll.id)),
                    child: const Text('Close'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(poll.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...poll.results.map((option) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 220,
                        child: Text(option.text,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: option.percentage / 100,
                            minHeight: 10,
                            backgroundColor: Colors.blueGrey.shade100,
                            valueColor: AlwaysStoppedAnimation(
                                Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(
                            '${option.votes} (${option.percentage.toStringAsFixed(0)}%)',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

TextStyle _label(BuildContext context) => Theme.of(context)
    .textTheme
    .labelSmall!
    .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Colors.blueGrey);
