// CSV export intentionally uses dart:html (web-only admin feature).
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_admin/core/theme.dart';
import 'package:feedback_admin/features/reports/reports_bloc.dart';

/// Report triage: searchable, filterable data table with multi-select,
/// bulk status updates, CSV export and a right-side detail drawer.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsBloc, ReportsState>(
      builder: (context, state) {
        if (state is ReportsFailure) {
          return Center(child: Text('Failed to load reports: ${state.message}'));
        }
        final s = state as ReportsLoaded;
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Toolbar(state: s),
                Expanded(child: _Table(state: s)),
              ],
            ),
            if (s.openDetail != null) const _DetailDrawer(),
          ],
        );
      },
    );
  }
}

class _Toolbar extends StatefulWidget {
  final ReportsLoaded state;

  const _Toolbar({required this.state});

  @override
  State<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<_Toolbar> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _apply({String? status, String? category}) {
    context.read<ReportsBloc>().add(ReportsFilterChanged(
          search: _searchController.text,
          status: status ?? widget.state.status,
          category: category ?? widget.state.category,
          assignedTo: widget.state.assignedTo,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Reports',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              if (s.loading)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              const Spacer(),
              if (s.selected.isNotEmpty) ...[
                Text('${s.selected.length} selected',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(width: 8),
                for (final status in const ['IN_REVIEW', 'RESOLVED', 'OPEN'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => context
                          .read<ReportsBloc>()
                          .add(ReportsBulkStatusChanged(status)),
                      child: Text('Mark ${status.toLowerCase().replaceAll('_', ' ')}',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                TextButton(
                  onPressed: () => context
                      .read<ReportsBloc>()
                      .add(const ReportsSelectionCleared()),
                  child: const Text('Clear'),
                ),
              ] else
                FilledButton.tonalIcon(
                  onPressed: () => _downloadCsv(s.reports),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export CSV'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                      hintText: 'Search reports…',
                      prefixIcon: Icon(Icons.search)),
                  onSubmitted: (_) => _apply(),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String?>(
                value: s.status,
                hint: const Text('Status'),
                items: const [
                  DropdownMenuItem(value: 'OPEN', child: Text('Open')),
                  DropdownMenuItem(value: 'IN_REVIEW', child: Text('In Review')),
                  DropdownMenuItem(value: 'RESOLVED', child: Text('Resolved')),
                ],
                onChanged: (v) => _apply(status: v),
              ),
              const SizedBox(width: 10),
              DropdownButton<String?>(
                value: s.category,
                hint: const Text('Category'),
                items: const [
                  DropdownMenuItem(value: 'ROADS', child: Text('Roads')),
                  DropdownMenuItem(value: 'WATER', child: Text('Water')),
                  DropdownMenuItem(value: 'ELECTRICITY', child: Text('Electricity')),
                  DropdownMenuItem(value: 'SANITATION', child: Text('Sanitation')),
                  DropdownMenuItem(value: 'TRANSPORT', child: Text('Transport')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                ],
                onChanged: (v) => _apply(category: v),
              ),
              const SizedBox(width: 10),
              TextButton(
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<ReportsBloc>()
                        .add(const ReportsFilterChanged());
                  },
                  child: const Text('Reset')),
            ],
          ),
        ],
      ),
    );
  }

  void _downloadCsv(List<AdminReport> reports) {
    final csv = ReportsBloc.toCsv(reports);
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..download = 'civicpulse-reports.csv'
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}

class _Table extends StatelessWidget {
  final ReportsLoaded state;

  const _Table({required this.state});

  @override
  Widget build(BuildContext context) {
    final reports = state.reports;
    if (reports.isEmpty && !state.loading) {
      return const Center(child: Text('No reports match the current filters.'));
    }
    final allSelected = reports.isNotEmpty &&
        reports.every((r) => state.selected.contains(r.id));
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        child: DataTable(
          headingTextStyle: const TextStyle(fontWeight: FontWeight.w700),
          columns: [
            DataColumn(
              label: Checkbox(
                value: allSelected,
                onChanged: (value) {
                for (final r in reports) {
                  context
                      .read<ReportsBloc>()
                      .add(ReportsToggled(r.id, value ?? false));
                }
              },
              ),
            ),
            const DataColumn(label: Text('ID')),
            const DataColumn(label: Text('Issue')),
            const DataColumn(label: Text('Category')),
            const DataColumn(label: Text('Status')),
            const DataColumn(label: Text('Upvotes')),
            const DataColumn(label: Text('Officer')),
            const DataColumn(label: Text('Created')),
          ],
          rows: reports.map((report) {
            return DataRow(
              selected: state.selected.contains(report.id),
              onSelectChanged: (_) => context.read<ReportsBloc>().add(
                  ReportsToggled(report.id, !state.selected.contains(report.id))),
              cells: [
                DataCell(Checkbox(
                  value: state.selected.contains(report.id),
                  onChanged: (value) => context.read<ReportsBloc>().add(
                      ReportsToggled(report.id, value ?? false)),
                )),
                DataCell(Text('#${report.id}')),
                DataCell(
                  InkWell(
                    onTap: () => context
                        .read<ReportsBloc>()
                        .add(ReportOpened(report.id)),
                    child: Text(report.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary)),
                  ),
                ),
                DataCell(Text(report.category)),
                DataCell(Row(children: [
                  StatusChip(status: report.status),
                  if (report.hidden) ...[
                    const SizedBox(width: 6),
                    const Tooltip(
                        message: 'Hidden from citizens',
                        child: Icon(Icons.visibility_off,
                            size: 16, color: Colors.grey)),
                  ],
                ])),
                DataCell(Text('${report.upvotes}')),
                DataCell(Text(report.assignedTo ?? '—')),
                DataCell(Text(report.createdAt.substring(0, 10))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Right-side operation drawer for one report.
class _DetailDrawer extends StatelessWidget {
  const _DetailDrawer();

  @override
  Widget build(BuildContext context) {
    final detail = (context.watch<ReportsBloc>().state as ReportsLoaded).openDetail!;
    final report = detail.report;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 480,
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Report #${report.id}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        context.read<ReportsBloc>().add(const DrawerClosed()),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _DrawerBody(detail: detail),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerBody extends StatefulWidget {
  final AdminReportDetail detail;

  const _DrawerBody({required this.detail});

  @override
  State<_DrawerBody> createState() => _DrawerBodyState();
}

class _DrawerBodyState extends State<_DrawerBody> {
  late String _status;
  late TextEditingController _officer;
  late TextEditingController _publicNote;
  late TextEditingController _internalNote;

  @override
  void initState() {
    super.initState();
    _status = widget.detail.report.status;
    _officer = TextEditingController(text: widget.detail.report.assignedTo ?? '');
    _publicNote = TextEditingController(text: widget.detail.publicNote);
    _internalNote = TextEditingController(text: widget.detail.internalNote);
  }

  @override
  void dispose() {
    _officer.dispose();
    _publicNote.dispose();
    _internalNote.dispose();
    super.dispose();
  }

  void _save({bool? hidden}) {
    context.read<ReportsBloc>().add(ReportSaved(
      reportId: widget.detail.report.id,
      newStatus: _status,
      assignedTo: _officer.text,
      publicNote: _publicNote.text,
      internalNote: _internalNote.text,
      hidden: hidden,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final report = detail.report;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StatusChip(status: report.status),
        const SizedBox(height: 10),
        if (detail.images.isNotEmpty) ...[
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final url in detail.images)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        url,
                        width: 160,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 160,
                          height: 120,
                          color: Colors.blueGrey.shade100,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(report.title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(report.description),
        const SizedBox(height: 8),
        Text('📍 ${report.latitude ?? '—'}, ${report.longitude ?? '—'}  ·  👍 ${report.upvotes} upvotes',
            style: Theme.of(context).textTheme.bodySmall),
        const Divider(height: 28),

        Text('OPERATIONS', style: _sectionStyle(context)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Status'),
          items: const [
            DropdownMenuItem(value: 'OPEN', child: Text('Open')),
            DropdownMenuItem(value: 'IN_REVIEW', child: Text('In Review')),
            DropdownMenuItem(value: 'RESOLVED', child: Text('Resolved')),
          ],
          onChanged: (v) => setState(() => _status = v ?? _status),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _officer,
          decoration:
              const InputDecoration(labelText: 'Assigned to (officer name)'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _publicNote,
          decoration: const InputDecoration(
              labelText: 'Public note',
              hintText: 'Visible to the citizen — e.g. inspection schedule'),
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: TextField(
            controller: _internalNote,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Internal note (staff only)',
              hintText: 'e.g. Team 3 handling',
              border: InputBorder.none,
              isDense: true,
            ),
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save changes'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => _save(hidden: !report.hidden),
              icon: Icon(report.hidden
                  ? Icons.visibility
                  : Icons.visibility_off),
              label: Text(report.hidden ? 'Unhide' : 'Hide'),
            ),
          ],
        ),
        const Divider(height: 28),

        Text('TIMELINE', style: _sectionStyle(context)),
        const SizedBox(height: 10),
        ...detail.history.map((h) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.check_circle,
                  size: 18, color: colorFor(h['newStatus'] as String? ?? '')),
              title: Text(
                  '${((h['oldStatus'] as String?) ?? '•').replaceAll('_', ' ')} → ${(h['newStatus'] as String? ?? '').replaceAll('_', ' ')}'),
              subtitle: Text('by user ${h['changedBy']} · ${h['changedAt']}',
                  style: Theme.of(context).textTheme.bodySmall),
            )),
        const Divider(height: 28),

        Text('COMMENTS (${detail.comments.length})',
            style: _sectionStyle(context)),
        const SizedBox(height: 8),
        if (detail.comments.isEmpty)
          Text('No comments.', style: Theme.of(context).textTheme.bodySmall)
        else
          ...detail.comments.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                    'Citizen #${c['userId']}: ${c['text']}',
                    style: Theme.of(context).textTheme.bodySmall),
              )),
        const SizedBox(height: 24),
      ],
    );
  }

  TextStyle _sectionStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .labelSmall!
      .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Colors.blueGrey);
}
