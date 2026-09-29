import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:feedback_app/core/l10n/entity_labels.dart';
import 'package:feedback_app/core/theme/status_colors.dart';
import 'package:feedback_app/shared/widgets/status_chips.dart';
import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';
import 'package:feedback_app/features/feedback/presentation/bloc/feedback_bloc.dart';
import 'package:feedback_app/features/feedback/presentation/pages/feedback_detail_page.dart';
import 'package:feedback_app/l10n/gen/app_localizations.dart';
import 'package:feedback_app/shared/widgets/states.dart';

/// Nearby-issues map: PostGIS near-me results plotted as status-colored
/// markers on OpenStreetMap, with category filter and a preview sheet.
class NearbyIssuesMapPage extends StatefulWidget {
  const NearbyIssuesMapPage({super.key});

  @override
  State<NearbyIssuesMapPage> createState() => _NearbyIssuesMapPageState();
}

class _NearbyIssuesMapPageState extends State<NearbyIssuesMapPage> {
  static const _fallbackCenter = LatLng(18.5204, 73.8567); // demo: Pune
  static const _radiusKm = 10.0;

  final _mapController = MapController();
  bool _mapReady = false;
  bool _usingFallback = false;
  LatLng _center = _fallbackCenter;

  @override
  void initState() {
    super.initState();
    _loadNearby();
  }

  /// Loads a wide radius around the device position; falls back to the
  /// demo center when the location is unavailable (denied, timeout, error)
  /// and shows a notice so the fallback is never presented as device-nearby.
  Future<void> _loadNearby() async {
    var center = _fallbackCenter;
    var usedFallback = true;
    try {
      final permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          ),
        );
        center = LatLng(position.latitude, position.longitude);
        usedFallback = false;
      }
    } catch (_) {
      // Keep the demo center — the map still loads.
    }
    if (!mounted) return;
    setState(() {
      _usingFallback = usedFallback;
      _center = center;
    });
    if (_mapReady) {
      _mapController.move(center, _mapController.camera.zoom);
    }
    context.read<FeedbackBloc>().add(NearbyFeedbackRequested(
        lat: center.latitude, lng: center.longitude, radiusKm: _radiusKm));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapTitle)),
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
            return ErrorState(message: state.message, onRetry: _loadNearby);
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 13,
                  onMapReady: () {
                    _mapReady = true;
                    if (_center != _fallbackCenter) {
                      _mapController.move(
                          _center, _mapController.camera.zoom);
                    }
                  },
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
                      _legendDot(StatusColors.open,
                          feedbackStatusLabel(context, 'OPEN')),
                      const SizedBox(width: 10),
                      _legendDot(StatusColors.inReview,
                          feedbackStatusLabel(context, 'IN_REVIEW')),
                      const SizedBox(width: 10),
                      _legendDot(StatusColors.resolved,
                          feedbackStatusLabel(context, 'RESOLVED')),
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
                      onPressed: _loadNearby,
                      tooltip: l10n.mapRecenter,
                      child: const Icon(Icons.my_location),
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
                      child: Text(l10n.mapReportsCount(geoItems.length),
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
              if (_usingFallback)
                Positioned(
                  left: 12,
                  right: 76,
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(l10n.locationFallbackNotice,
                        style: Theme.of(context).textTheme.bodySmall),
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
    final l10n = AppLocalizations.of(context);
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
                child: Text(l10n.mapViewReport),
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
