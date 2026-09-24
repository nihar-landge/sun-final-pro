import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_admin/core/theme.dart';
import 'package:feedback_admin/features/audit/audit_bloc.dart';

/// Audit log — searchable history of every status transition.
class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AuditBloc>().add(const AuditRefreshed());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuditBloc, AuditState>(
      builder: (context, state) {
        final entries =
            state is AuditLoaded ? state.entries : const <AuditEntry>[];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('Audit Log',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                          hintText: 'Search by title or actor id…',
                          prefixIcon: Icon(Icons.search)),
                      onSubmitted: (value) => context
                          .read<AuditBloc>()
                          .add(AuditRefreshed(search: value)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: () => context
                        .read<AuditBloc>()
                        .add(const AuditRefreshed()),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (state is AuditLoading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (state is AuditFailure)
                Expanded(child: Center(child: Text(state.message)))
              else if (entries.isEmpty)
                const Expanded(
                    child: Center(child: Text('No audit entries yet.')))
              else
                Expanded(
                  child: Card(
                    child: DataTable(
                      headingTextStyle:
                          const TextStyle(fontWeight: FontWeight.w700),
                      columns: const [
                        DataColumn(label: Text('When')),
                        DataColumn(label: Text('Report')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Transition')),
                        DataColumn(label: Text('Actor')),
                      ],
                      rows: entries
                          .map((entry) => DataRow(cells: [
                                DataCell(Text(entry.changedAt.length >= 16
                                    ? entry.changedAt.substring(0, 16)
                                        .replaceAll('T', ' ')
                                    : entry.changedAt)),
                                DataCell(Text(
                                    '#${entry.feedbackId} ${entry.reportTitle}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600))),
                                DataCell(Text(entry.category ?? '—')),
                                DataCell(Row(children: [
                                  Text(
                                      (entry.oldStatus ?? '•')
                                          .replaceAll('_', ' '),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                  const Icon(Icons.arrow_forward,
                                      size: 14, color: Colors.blueGrey),
                                  StatusChip(status: entry.newStatus),
                                ])),
                                DataCell(Text(entry.changedBy == null
                                    ? 'system'
                                    : 'user ${entry.changedBy}')),
                              ]))
                          .toList(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
