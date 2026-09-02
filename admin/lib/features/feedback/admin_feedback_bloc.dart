import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_admin/core/api_client.dart';

/// Feedback triage for admins: filter by status and transition them.
class AdminFeedback extends Equatable {
  final int id;
  final String title;
  final String description;
  final String category;
  final String status;
  final int upvotes;

  const AdminFeedback({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.upvotes,
  });

  factory AdminFeedback.fromJson(Map<String, dynamic> json) => AdminFeedback(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'OTHER',
        status: json['status'] as String? ?? 'OPEN',
        upvotes: (json['upvotes'] as num? ?? 0).toInt(),
      );

  @override
  List<Object?> get props => [id, title, description, category, status, upvotes];
}

sealed class AdminFeedbackEvent extends Equatable {
  const AdminFeedbackEvent();

  @override
  List<Object?> get props => [];
}

class AdminFeedbackRefreshed extends AdminFeedbackEvent {
  final String? status;

  const AdminFeedbackRefreshed({this.status});

  @override
  List<Object?> get props => [status];
}

class AdminFeedbackStatusChanged extends AdminFeedbackEvent {
  final int feedbackId;
  final String newStatus;

  const AdminFeedbackStatusChanged({required this.feedbackId, required this.newStatus});

  @override
  List<Object?> get props => [feedbackId, newStatus];
}

sealed class AdminFeedbackState extends Equatable {
  const AdminFeedbackState();

  @override
  List<Object?> get props => [];
}

class AdminFeedbackLoading extends AdminFeedbackState {
  const AdminFeedbackLoading();
}

class AdminFeedbackLoaded extends AdminFeedbackState {
  final List<AdminFeedback> items;

  const AdminFeedbackLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class AdminFeedbackMessage extends AdminFeedbackState {
  final List<AdminFeedback> items;
  final String message;

  const AdminFeedbackMessage(this.items, this.message);

  @override
  List<Object?> get props => [items, message];
}

class AdminFeedbackFailure extends AdminFeedbackState {
  final String message;

  const AdminFeedbackFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminFeedbackBloc extends Bloc<AdminFeedbackEvent, AdminFeedbackState> {
  final AdminApiClient apiClient;

  AdminFeedbackBloc({required this.apiClient}) : super(const AdminFeedbackLoading()) {
    on<AdminFeedbackRefreshed>(_onRefresh);
    on<AdminFeedbackStatusChanged>(_onStatusChange);
    add(const AdminFeedbackRefreshed());
  }

  List<AdminFeedback> _current(AdminFeedbackState state) => switch (state) {
        AdminFeedbackLoaded s => s.items,
        AdminFeedbackMessage s => s.items,
        _ => const <AdminFeedback>[],
      };

  Future<void> _onRefresh(AdminFeedbackRefreshed event, Emitter<AdminFeedbackState> emit) async {
    emit(const AdminFeedbackLoading());
    try {
      final query = event.status == null ? '' : '?status=${event.status}';
      final data = await apiClient.request('/feedback$query');
      final content = data is Map<String, dynamic> ? data['content'] : data;
      final items = (content as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AdminFeedback.fromJson)
          .toList();
      emit(AdminFeedbackLoaded(items));
    } on AdminApiException catch (e) {
      emit(AdminFeedbackFailure(e.message));
    }
  }

  Future<void> _onStatusChange(
      AdminFeedbackStatusChanged event, Emitter<AdminFeedbackState> emit) async {
    try {
      await apiClient.request('/feedback/${event.feedbackId}/status',
          method: 'POST', body: {'newStatus': event.newStatus});
      emit(AdminFeedbackMessage(_current(state), 'Status updated to ${event.newStatus}'));
      add(const AdminFeedbackRefreshed());
    } on AdminApiException catch (e) {
      emit(AdminFeedbackFailure(e.message));
    }
  }
}
