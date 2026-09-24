import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_admin/core/api_client.dart';

/// Audit log: every status transition across all reports, newest first.
class AuditEntry extends Equatable {
  final int id;
  final int feedbackId;
  final String reportTitle;
  final String? category;
  final String? oldStatus;
  final String newStatus;
  final int? changedBy;
  final String changedAt;

  const AuditEntry({
    required this.id,
    required this.feedbackId,
    required this.reportTitle,
    this.category,
    this.oldStatus,
    required this.newStatus,
    this.changedBy,
    required this.changedAt,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        id: (json['id'] as num).toInt(),
        feedbackId: (json['feedbackId'] as num).toInt(),
        reportTitle: json['reportTitle'] as String? ?? '',
        category: json['category'] as String?,
        oldStatus: json['oldStatus'] as String?,
        newStatus: json['newStatus'] as String? ?? '',
        changedBy: (json['changedBy'] as num?)?.toInt(),
        changedAt: json['changedAt'] as String? ?? '',
      );

  @override
  List<Object?> get props =>
      [id, feedbackId, reportTitle, oldStatus, newStatus, changedBy, changedAt];
}

sealed class AuditEvent extends Equatable {
  const AuditEvent();

  @override
  List<Object?> get props => [];
}

class AuditRefreshed extends AuditEvent {
  final String search;

  const AuditRefreshed({this.search = ''});

  @override
  List<Object?> get props => [search];
}

sealed class AuditState extends Equatable {
  const AuditState();

  @override
  List<Object?> get props => [];
}

class AuditLoading extends AuditState {
  const AuditLoading();
}

class AuditLoaded extends AuditState {
  final List<AuditEntry> entries;
  final String search;

  const AuditLoaded(this.entries, {this.search = ''});

  @override
  List<Object?> get props => [entries, search];
}

class AuditFailure extends AuditState {
  final String message;

  const AuditFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuditBloc extends Bloc<AuditEvent, AuditState> {
  final AdminApiClient apiClient;

  AuditBloc({required this.apiClient}) : super(const AuditLoading()) {
    on<AuditRefreshed>(_onRefresh);
  }

  Future<void> _onRefresh(AuditRefreshed event, Emitter<AuditState> emit) async {
    emit(const AuditLoading());
    try {
      final data = await apiClient.request('/feedback/admin/audit?limit=200');
      var entries = (data as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AuditEntry.fromJson)
          .toList();
      final term = event.search.trim().toLowerCase();
      if (term.isNotEmpty) {
        entries = entries
            .where((e) =>
                e.reportTitle.toLowerCase().contains(term) ||
                (e.changedBy?.toString() ?? '').contains(term))
        .toList();
      }
      emit(AuditLoaded(entries, search: event.search));
    } on AdminApiException catch (e) {
      emit(AuditFailure(e.message));
    }
  }
}
