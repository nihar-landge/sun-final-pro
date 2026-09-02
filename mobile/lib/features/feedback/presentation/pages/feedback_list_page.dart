import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';
import 'package:feedback_app/features/feedback/presentation/bloc/feedback_bloc.dart';
import 'package:feedback_app/features/feedback/presentation/pages/submit_feedback_page.dart';

/// City feedback list with status filters and upvoting.
class FeedbackListPage extends StatelessWidget {
  const FeedbackListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('City Feedback')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const SubmitFeedbackPage(),
        )),
        icon: const Icon(Icons.add),
        label: const Text('Report issue'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: true,
                  onTap: () => context.read<FeedbackBloc>().add(const FeedbackListRequested()),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Open',
                  selected: false,
                  onTap: () => context
                      .read<FeedbackBloc>()
                      .add(const FeedbackListRequested(status: 'OPEN')),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'In review',
                  selected: false,
                  onTap: () => context
                      .read<FeedbackBloc>()
                      .add(const FeedbackListRequested(status: 'IN_REVIEW')),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Resolved',
                  selected: false,
                  onTap: () => context
                      .read<FeedbackBloc>()
                      .add(const FeedbackListRequested(status: 'RESOLVED')),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<FeedbackBloc, FeedbackState>(
              listener: (context, state) {
                if (state is FeedbackFailure) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                final items = switch (state) {
                  FeedbackLoaded s => s.items,
                  FeedbackLoading s => s.items,
                  FeedbackActionSuccess s => s.items,
                  _ => const <FeedbackItem>[],
                };
                if (state is FeedbackLoading && items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (items.isEmpty) {
                  return const Center(
                      child: Text('Nothing here yet.\nBe the first to report an issue!',
                          textAlign: TextAlign.center));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _FeedbackCard(item: items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final FeedbackItem item;

  const _FeedbackCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = switch (item.status) {
      FeedbackStatus.open => scheme.tertiary,
      FeedbackStatus.inReview => scheme.primary,
      FeedbackStatus.resolved => Colors.green,
    };

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_categoryIcon(item.category),
                    size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Text(item.category.name.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(item.status.name.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(item.description,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => context
                      .read<FeedbackBloc>()
                      .add(UpvoteRequested(item.id)),
                  icon: const Icon(Icons.thumb_up_outlined, size: 18),
                  label: Text('${item.upvotes}'),
                ),
                if (item.latitude != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.location_on_outlined,
                      size: 16, color: scheme.outline),
                  Text('geo-tagged', style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(FeedbackCategory category) => switch (category) {
        FeedbackCategory.roads => Icons.construction,
        FeedbackCategory.water => Icons.water_drop_outlined,
        FeedbackCategory.electricity => Icons.bolt,
        FeedbackCategory.sanitation => Icons.cleaning_services_outlined,
        FeedbackCategory.transport => Icons.directions_bus_outlined,
        FeedbackCategory.other => Icons.report_problem_outlined,
      };
}
