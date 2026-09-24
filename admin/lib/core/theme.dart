import 'package:flutter/material.dart';

/// Shared design tokens and small widgets for the CivicPulse admin console.
class AdminTheme {
  AdminTheme._();

  static const seed = Color(0xFF283593);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.blueGrey.shade100),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      );
}

const statusColor = {
  'OPEN': Color(0xFFE65100),
  'IN_REVIEW': Color(0xFFF9A825),
  'RESOLVED': Color(0xFF2E7D32),
};

const pollStatusColor = {
  'ACTIVE': Color(0xFF00695C),
  'SCHEDULED': Color(0xFF1565C0),
  'CLOSED': Colors.blueGrey,
};

Color colorFor(String status, {bool poll = false}) =>
    (poll ? pollStatusColor : statusColor)[status] ?? Colors.blueGrey;

class StatusChip extends StatelessWidget {
  final String status;
  final bool poll;

  const StatusChip({super.key, required this.status, this.poll = false});

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status, poll: poll);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.replaceAll('_', ' '),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}

class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(label,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal distribution bars (no chart dependency).
class DistributionBars extends StatelessWidget {
  final Map<String, int> data;
  final bool pollColors;

  const DistributionBars({super.key, required this.data, this.pollColors = false});

  @override
  Widget build(BuildContext context) {
    final max = data.values.fold<int>(1, (m, v) => v > m ? v : m);
    final total = data.values.fold<int>(0, (s, v) => s + v);
    return Column(
      children: data.entries.map((entry) {
        final color = colorFor(entry.key, poll: pollColors);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                  width: 110,
                  child: Text(entry.key.replaceAll('_', ' '),
                      style: Theme.of(context).textTheme.bodySmall)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entry.value / max,
                    minHeight: 10,
                    backgroundColor: Colors.blueGrey.shade100,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  total == 0
                      ? '0'
                      : '${entry.value} (${(entry.value * 100 / total).round()}%)',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
