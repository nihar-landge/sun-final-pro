import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:feedback_admin/core/theme.dart';
import 'package:feedback_admin/features/reports/reports_bloc.dart';

/// Live issue map — OpenStreetMap with status-colored pins; clicking a pin
/// opens the report's operation drawer.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const _center = LatLng(18.5204, 73.8567); // demo: Pune

  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(const ReportsFilterChanged());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsBloc, ReportsState>(
      builder: (context, state) {
        final reports =
            state is ReportsLoaded ? state.reports : const <AdminReport>[];
        final geo = reports
            .where((r) => r.latitude != null && r.longitude != null)
            .toList();
        return Stack(
          children: [
            FlutterMap(
              options: const MapOptions(initialCenter: _center, initialZoom: 12),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.feedback_admin',
                ),
                MarkerLayer(
                  markers: geo
                      .map((r) => Marker(
                            point: LatLng(r.latitude!, r.longitude!),
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              onTap: () => context
                                  .read<ReportsBloc>()
                                  .add(ReportOpened(r.id)),
                              child: _Pin(
                                  color: colorFor(r.status),
                                  label: '${r.upvotes}'),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final entry in statusColor.entries)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blueGrey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: entry.value, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(entry.key.replaceAll('_', ' '),
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueGrey.shade200),
                    ),
                    child: Text('${geo.length} pinned reports',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
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
