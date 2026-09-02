import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_admin/core/api_client.dart';

/// Poll management for admins: list, create, close, view results.
class AdminPoll extends Equatable {
  final int id;
  final String title;
  final String status;
  final int totalVotes;
  final List<Option> results;

  const AdminPoll({
    required this.id,
    required this.title,
    required this.status,
    required this.totalVotes,
    required this.results,
  });

  factory AdminPoll.fromJson(Map<String, dynamic> json) => AdminPoll(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        status: json['status'] as String? ?? 'CLOSED',
        totalVotes: (json['totalVotes'] as num? ?? 0).toInt(),
        results: (json['results'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(Option.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [id, title, status, totalVotes, results];
}

class Option extends Equatable {
  final int optionId;
  final String text;
  final int votes;
  final double percentage;

  const Option({required this.optionId, required this.text, required this.votes, required this.percentage});

  factory Option.fromJson(Map<String, dynamic> json) => Option(
        optionId: (json['optionId'] as num).toInt(),
        text: json['text'] as String? ?? '',
        votes: (json['votes'] as num? ?? 0).toInt(),
        percentage: (json['percentage'] as num? ?? 0).toDouble(),
      );

  @override
  List<Object?> get props => [optionId, text, votes, percentage];
}

sealed class AdminPollsEvent extends Equatable {
  const AdminPollsEvent();

  @override
  List<Object?> get props => [];
}

class AdminPollsRefreshed extends AdminPollsEvent {
  final String status;

  const AdminPollsRefreshed({this.status = 'all'});

  @override
  List<Object?> get props => [status];
}

class AdminPollCreated extends AdminPollsEvent {
  final String title;
  final String description;
  final List<String> options;

  const AdminPollCreated(
      {required this.title, required this.description, required this.options});

  @override
  List<Object?> get props => [title, description, options];
}

class AdminPollClosed extends AdminPollsEvent {
  final int pollId;

  const AdminPollClosed(this.pollId);

  @override
  List<Object?> get props => [pollId];
}

sealed class AdminPollsState extends Equatable {
  const AdminPollsState();

  @override
  List<Object?> get props => [];
}

class AdminPollsLoading extends AdminPollsState {
  const AdminPollsLoading();
}

class AdminPollsLoaded extends AdminPollsState {
  final List<AdminPoll> polls;

  const AdminPollsLoaded(this.polls);

  @override
  List<Object?> get props => [polls];
}

class AdminPollsMessage extends AdminPollsState {
  final List<AdminPoll> polls;
  final String message;

  const AdminPollsMessage(this.polls, this.message);

  @override
  List<Object?> get props => [polls, message];
}

class AdminPollsFailure extends AdminPollsState {
  final String message;

  const AdminPollsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminPollsBloc extends Bloc<AdminPollsEvent, AdminPollsState> {
  final AdminApiClient apiClient;

  AdminPollsBloc({required this.apiClient}) : super(const AdminPollsLoading()) {
    on<AdminPollsRefreshed>(_onRefresh);
    on<AdminPollCreated>(_onCreate);
    on<AdminPollClosed>(_onClose);
    add(const AdminPollsRefreshed());
  }

  Future<void> _onRefresh(AdminPollsRefreshed event, Emitter<AdminPollsState> emit) async {
    emit(const AdminPollsLoading());
    try {
      final data = await apiClient.request('/polls?status=${event.status}');
      final polls = (data as List).whereType<Map<String, dynamic>>().map(AdminPoll.fromJson).toList();
      emit(AdminPollsLoaded(polls));
    } on AdminApiException catch (e) {
      emit(AdminPollsFailure(e.message));
    }
  }

  Future<void> _onCreate(AdminPollCreated event, Emitter<AdminPollsState> emit) async {
    final current = state is AdminPollsLoaded
        ? (state as AdminPollsLoaded).polls
        : state is AdminPollsMessage
            ? (state as AdminPollsMessage).polls
            : const <AdminPoll>[];
    try {
      final now = DateTime.now();
      String iso(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:00';
      await apiClient.request('/polls', method: 'POST', body: {
        'title': event.title,
        'description': event.description,
        'startTime': iso(now),
        'endTime': iso(now.add(const Duration(days: 7))),
        'isAnonymous': true,
        'options': event.options,
      });
      emit(AdminPollsMessage(current, 'Poll created'));
      add(const AdminPollsRefreshed());
    } on AdminApiException catch (e) {
      emit(AdminPollsFailure(e.message));
    }
  }

  Future<void> _onClose(AdminPollClosed event, Emitter<AdminPollsState> emit) async {
    final current = state is AdminPollsLoaded
        ? (state as AdminPollsLoaded).polls
        : state is AdminPollsMessage
            ? (state as AdminPollsMessage).polls
            : const <AdminPoll>[];
    try {
      await apiClient.request('/polls/${event.pollId}/close', method: 'POST');
      emit(AdminPollsMessage(current, 'Poll closed'));
      add(const AdminPollsRefreshed());
    } on AdminApiException catch (e) {
      emit(AdminPollsFailure(e.message));
    }
  }
}
