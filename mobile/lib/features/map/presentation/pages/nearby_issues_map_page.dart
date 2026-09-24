import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:feedback_app/core/theme/status_colors.dart';
import 'package:feedback_app/shared/widgets/status_chips.dart';
import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';
import 'package:feedback_app/features/feedback/presentation/bloc/feedback_bloc.dart';
import 'package:feedback_app/features/feedback/presentation/pages/feedback_detail_page.dart';
import 'package:feedback_app/shared/widgets/states.dart';

/// Nearby-issues map: PostGIS near-me results plotted as status-colored
/// markers on OpenStreetMap, with category filter and a preview sheet.
class NearbyIssuesMapPage extends StatefulWidget {
  const NearbyIssuesMapPage({super.key});

  @override
  State<NearbyIssuesMapPage> createState() => _NearbyIssuesMapPageState();
}

class _NearbyIssuesMapPageState extends State<NearbyIssuesMapPage> {
  static const _center = LatLng(18.5204, 73.8567); // demo: Pune

  @override
  void initState() {
    super.initState();
    // Load a wide radius around the demo center.
    context.read<FeedbackBloc>().add(const NearbyFeedbackRequested(lat: 18.5204, lng: 73.8567, radiusKm: 10));
  }

  void _refresh() {
    context.read<FeedbackBloc>().add(const NearbyFeedbackRequested(lat: 18.5204, lng: 73.8567, radiusKm: 10));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Issues Near You')),
      body: BlocConsumer<FeedbackBloc, FeedbackState>(
        listener: (context, state) {
          if (state is FeedbackFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final items = switch (state) {
            FeedbackLoaded s when s.nearby => s.items,
            _ => const <FeedbackItem>[],
          };
          final geoItems = items
              .whereType<FeedbackItem>()
              .where((i) => i.latitude != null && i.longitude != null)
              .toList();

          if (state is FeedbackLoading && geoItems.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FeedbackFailure && geoItems.isEmpty) {
            return ErrorState(message: state.message, onRetry: _refresh);
          }

          return Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: _center,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.feedback_app',
                  ),
                  MarkerLayer(
                    markers: geoItems.map((item) {
                      final color = StatusColors.forStatus(item.status.name);
                      return Marker(
                        point: LatLng(item.latitude!, item.longitude!),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showPreview(item),
                          child: _Pin(color: color, label: '${item.upvotes}'),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              // legend
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _legendDot(StatusColors.open, 'Open'),
                      const SizedBox(width: 10),
                      _legendDot(StatusColors.inReview, 'Review'),
                      const SizedBox(width: 10),
                      _legendDot(StatusColors.resolved, 'Resolved'),
                    ],
                  ),
                ),
              ),
              // recenter + count
              Positioned(
                right: 12,
                bottom: 24,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'recenter',
                      onPressed: _refresh,
                      child: const Icon(Icons.refresh),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Text('${geoItems.length} reports',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  void _showPreview(FeedbackItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip(status: item.status.name),
                const Spacer(),
                Text('👍 ${item.upvotes}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            Text(item.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(item.description,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        FeedbackDetailPage(feedbackId: item.id),
                  ));
                },
                child: const Text('View Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final Color color;
  final String label;

  const _Pin({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
        Icon(Icons.arrow_drop_down, color: color, size: 16),
      ],
    );
  }
}
