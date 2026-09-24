import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_admin/core/api_client.dart';

/// Report triage state: filtered table, multi-select, bulk status changes,
/// detail for the right-side drawer, and CSV export.
class AdminReport extends Equatable {
  final int id;
  final String title;
  final String description;
  final String category;
  final String status;
  final int upvotes;
  final String? assignedTo;
  final bool hidden;
  final double? latitude;
  final double? longitude;
  final String createdAt;

  const AdminReport({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.upvotes,
    this.assignedTo,
    this.hidden = false,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory AdminReport.fromJson(Map<String, dynamic> json) => AdminReport(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'OTHER',
        status: json['status'] as String? ?? 'OPEN',
        upvotes: (json['upvotes'] as num? ?? 0).toInt(),
        assignedTo: json['assignedTo'] as String?,
        hidden: json['hidden'] as bool? ?? false,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        createdAt: json['createdAt'] as String? ?? '',
      );

  AdminReport copyWith({String? status, String? assignedTo, bool? hidden}) =>
      AdminReport(
        id: id,
        title: title,
        description: description,
        category: category,
        status: status ?? this.status,
        upvotes: upvotes,
        assignedTo: assignedTo ?? this.assignedTo,
        hidden: hidden ?? this.hidden,
        latitude: latitude,
        longitude: longitude,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, title, category, status, upvotes, assignedTo, hidden, createdAt];
}

/// Full detail payload for the drawer.
class AdminReportDetail extends Equatable {
  final AdminReport report;
  final String publicNote;
  final String internalNote;
  final List<Map<String, dynamic>> comments;
  final List<Map<String, dynamic>> history;

  const AdminReportDetail({
    required this.report,
    required this.publicNote,
    required this.internalNote,
    required this.comments,
    required this.history,
  });

  @override
  List<Object?> get props => [report, publicNote, internalNote, comments, history];
}

sealed class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class ReportsFilterChanged extends ReportsEvent {
  final String search;
  final String? status;
  final String? category;
  final String? assignedTo;

  const ReportsFilterChanged({
    this.search = '',
    this.status,
    this.category,
    this.assignedTo,
  });

  @override
  List<Object?> get props => [search, status, category, assignedTo];
}

class ReportOpened extends ReportsEvent {
  final int reportId;

  const ReportOpened(this.reportId);

  @override
  List<Object?> get props => [reportId];
}

class ReportsToggled extends ReportsEvent {
  final int reportId;
  final bool selected;

  const ReportsToggled(this.reportId, this.selected);

  @override
  List<Object?> get props => [reportId, selected];
}

class ReportsSelectionCleared extends ReportsEvent {
  const ReportsSelectionCleared();
}

class ReportsBulkStatusChanged extends ReportsEvent {
  final String newStatus;

  const ReportsBulkStatusChanged(this.newStatus);

  @override
  List<Object?> get props => [newStatus];
}

class ReportsRefreshed extends ReportsEvent {
  const ReportsRefreshed();
}

class ReportSaved extends ReportsEvent {
  final int reportId;
  final String newStatus;
  final String assignedTo;
  final String publicNote;
  final String internalNote;
  final bool? hidden;

  const ReportSaved({
    required this.reportId,
    required this.newStatus,
    required this.assignedTo,
    required this.publicNote,
    required this.internalNote,
    this.hidden,
  });

  @override
  List<Object?> get props =>
      [reportId, newStatus, assignedTo, publicNote, internalNote, hidden];
}

class DrawerClosed extends ReportsEvent {
  const DrawerClosed();
}

sealed class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsLoaded extends ReportsState {
  final List<AdminReport> reports;
  final String search;
  final String? status;
  final String? category;
  final String? assignedTo;
  final Set<int> selected;
  final AdminReportDetail? openDetail;
  final String? message;
  final bool loading;

  const ReportsLoaded({
    required this.reports,
    this.search = '',
    this.status,
    this.category,
    this.assignedTo,
    this.selected = const {},
    this.openDetail,
    this.message,
    this.loading = false,
  });

  @override
  List<Object?> get props =>
      [reports, search, status, category, assignedTo, selected, openDetail, message, loading];
}

class ReportsFailure extends ReportsState {
  final String message;

  const ReportsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final AdminApiClient apiClient;

  ReportsBloc({required this.apiClient}) : super(const ReportsFailure('init')) {
    on<ReportsFilterChanged>(_onFilter);
    on<ReportOpened>(_onOpen);
    on<ReportsToggled>(_onToggle);
    on<ReportsSelectionCleared>(_onClearSelection);
    on<ReportsBulkStatusChanged>(_onBulkStatus);
    on<ReportsRefreshed>(_onRefreshEvent);
    on<ReportSaved>(_onSave);
    on<DrawerClosed>(_onDrawerClosed);
    add(ReportsFilterChanged());
  }

  Future<List<AdminReport>> _fetch({
    String search = '',
    String? status,
    String? category,
    String? assignedTo,
  }) async {
    final params = <String>[
      'size=100',
      'includeHidden=true',
      if (search.trim().isNotEmpty) 'search=${Uri.encodeQueryComponent(search.trim())}',
      if (status != null) 'status=$status',
      if (category != null) 'category=$category',
    ];
    final data = await apiClient.request('/feedback?${params.join('&')}');
    final content = data is Map<String, dynamic> ? data['content'] : data;
    var reports = (content as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AdminReport.fromJson)
        .toList();
    if (assignedTo != null && assignedTo.isNotEmpty) {
      reports = reports
          .where((r) =>
              (r.assignedTo ?? '').toLowerCase().contains(assignedTo.toLowerCase()))
          .toList();
    }
    return reports;
  }

  ReportsLoaded _current() =>
      state is ReportsLoaded ? state as ReportsLoaded : const ReportsLoaded(reports: []);

  Future<void> _onFilter(ReportsFilterChanged event, Emitter<ReportsState> emit) async {
    emit(ReportsLoaded(
      reports: _current().reports,
      search: event.search,
      status: event.status,
      category: event.category,
      assignedTo: event.assignedTo,
      loading: true,
    ));
    try {
      final reports = await _fetch(
        search: event.search,
        status: event.status,
        category: event.category,
        assignedTo: event.assignedTo,
      );
      emit(ReportsLoaded(
        reports: reports,
        search: event.search,
        status: event.status,
        category: event.category,
        assignedTo: event.assignedTo,
        openDetail: _current().openDetail,
      ));
    } on AdminApiException catch (e) {
      emit(ReportsFailure(e.message));
    }
  }

  Future<void> _onOpen(ReportOpened event, Emitter<ReportsState> emit) async {
    final current = _current();
    emit(ReportsLoaded(
      reports: current.reports,
      search: current.search, status: current.status,
      category: current.category, assignedTo: current.assignedTo,
      selected: current.selected, loading: true,
    ));
    try {
      final data = await apiClient.request('/feedback/${event.reportId}');
      emit(current.copyWith(openDetail: AdminReportDetail(
        report: AdminReport.fromJson(data),
        publicNote: data['publicNote'] as String? ?? '',
        internalNote: data['internalNote'] as String? ?? '',
        comments: (data['comments'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList(),
        history: (data['history'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList(),
      )));
    } on AdminApiException catch (e) {
      emit(current.copyWith(message: e.message));
    }
  }

  Future<void> _onToggle(ReportsToggled event, Emitter<ReportsState> emit) async {
    final current = _current();
    final selected = {...current.selected};
    if (event.selected) {
      selected.add(event.reportId);
    } else {
      selected.remove(event.reportId);
    }
    emit(current.copyWith(selected: selected));
  }

  Future<void> _onClearSelection(ReportsSelectionCleared event, Emitter<ReportsState> emit) async {
    emit(_current().copyWith(selected: {}));
  }

  Future<void> _onBulkStatus(ReportsBulkStatusChanged event, Emitter<ReportsState> emit) async {
    final current = _current();
    int changed = 0, failed = 0;
    for (final id in current.selected) {
      try {
        await apiClient.request('/feedback/$id', method: 'PATCH', body: {'newStatus': event.newStatus});
        changed++;
      } on AdminApiException {
        failed++;
      }
    }
    emit(current.copyWith(
        selected: {}, message: 'Bulk update: $changed changed${failed == 0 ? '' : ', $failed skipped'}'));
    add(ReportsFilterChanged(
        search: current.search, status: current.status,
        category: current.category, assignedTo: current.assignedTo));
  }

  Future<void> _onSave(ReportSaved event, Emitter<ReportsState> emit) async {
    final current = _current();
    emit(current.copyWith(message: null));
    try {
      await apiClient.request('/feedback/${event.reportId}', method: 'PATCH', body: {
        'newStatus': event.newStatus,
        'assignedTo': event.assignedTo,
        'publicNote': event.publicNote,
        'internalNote': event.internalNote,
        if (event.hidden != null) 'hidden': event.hidden,
      });
      emit(current.copyWith(message: 'Report #${event.reportId} updated'));
      add(ReportOpened(event.reportId));
    } on AdminApiException catch (e) {
      emit(current.copyWith(message: e.message));
    }
  }

  Future<void> _onDrawerClosed(DrawerClosed event, Emitter<ReportsState> emit) async {
    final current = _current();
    emit(ReportsLoaded(
      reports: current.reports,
      search: current.search, status: current.status,
      category: current.category, assignedTo: current.assignedTo,
      selected: current.selected,
    ));
    add(ReportsFilterChanged(
        search: current.search, status: current.status,
        category: current.category, assignedTo: current.assignedTo));
  }

  Future<void> _onRefreshEvent(ReportsRefreshed event, Emitter<ReportsState> emit) async {
    final current = _current();
    add(ReportsFilterChanged(
        search: current.search, status: current.status,
        category: current.category, assignedTo: current.assignedTo));
  }

  /// CSV of the current table view (client-side export).
  static String toCsv(List<AdminReport> reports) {
    String esc(String v) => '"${v.replaceAll('"', '""')}"';
    final buffer = StringBuffer(
        'id,category,title,status,upvotes,assigned_to,hidden,created_at\n');
    for (final r in reports) {
      buffer.writeln([
        r.id, esc(r.category), esc(r.title), r.status, r.upvotes,
        esc(r.assignedTo ?? ''), r.hidden, esc(r.createdAt),
      ].join(','));
    }
    return buffer.toString();
  }
}

extension on ReportsLoaded {
  ReportsLoaded copyWith({
    Set<int>? selected,
    AdminReportDetail? openDetail,
    String? message,
  }) =>
      ReportsLoaded(
        reports: reports,
        search: search, status: status, category: category, assignedTo: assignedTo,
        selected: selected ?? this.selected,
        openDetail: openDetail ?? this.openDetail,
        message: message,
      );
}
