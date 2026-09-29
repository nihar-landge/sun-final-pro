import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/errors/exceptions.dart';
import 'package:feedback_app/features/alerts/data/datasources/notification_remote_data_source.dart';

/// The citizen's notification inbox — persistent rows created by consumed
/// RabbitMQ events, with unread tracking and mark-read.
sealed class AlertsEvent extends Equatable {
  const AlertsEvent();

  @override
  List<Object?> get props => [];
}

class AlertsRefreshed extends AlertsEvent {
  const AlertsRefreshed();
}

class NotificationMarkRead extends AlertsEvent {
  final int notificationId;

  const NotificationMarkRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class AllMarkedRead extends AlertsEvent {
  const AllMarkedRead();
}

class AlertItem extends Equatable {
  final int id;
  final String type;
  final String title;
  final String body;
  final bool unread;
  final int? refId;
  final String createdAt;

  const AlertItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.unread,
    this.refId,
    required this.createdAt,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) => AlertItem(
        id: (json['id'] as num).toInt(),
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        unread: json['unread'] as bool? ?? false,
        refId: (json['refId'] as num?)?.toInt(),
        createdAt: json['createdAt'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, type, title, body, unread, refId, createdAt];
}

sealed class AlertsState extends Equatable {
  const AlertsState();

  @override
  List<Object?> get props => [];
}

class AlertsLoading extends AlertsState {
  const AlertsLoading();
}

class AlertsLoaded extends AlertsState {
  final List<AlertItem> items;
  final int unreadCount;

  const AlertsLoaded(this.items, {this.unreadCount = 0});

  @override
  List<Object?> get props => [items, unreadCount];
}

class AlertsFailure extends AlertsState {
  final String message;

  const AlertsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  final NotificationRemoteDataSource remoteDataSource;

  AlertsBloc({required this.remoteDataSource}) : super(const AlertsLoading()) {
    on<AlertsRefreshed>(_onRefresh);
    on<NotificationMarkRead>(_onMarkRead);
    on<AllMarkedRead>(_onMarkAll);
  }

  Future<void> _onRefresh(AlertsRefreshed event, Emitter<AlertsState> emit) async {
    emit(const AlertsLoading());
    try {
      final rows = await remoteDataSource.inbox();
      final items = rows.map(AlertItem.fromJson).toList();
      final unread = items.where((i) => i.unread).length;
      emit(AlertsLoaded(items, unreadCount: unread));
    } catch (error) {
      emit(AlertsFailure(_messageFor(error)));
    }
  }

  Future<void> _onMarkRead(NotificationMarkRead event, Emitter<AlertsState> emit) async {
    final current = state;
    if (current is! AlertsLoaded) return;
    try {
      await remoteDataSource.markRead(event.notificationId);
      final items = current.items
          .map((i) => i.id == event.notificationId
              ? AlertItem(
                  id: i.id, type: i.type, title: i.title, body: i.body,
                  unread: false, refId: i.refId, createdAt: i.createdAt)
              : i)
          .toList();
      emit(AlertsLoaded(items,
          unreadCount: items.where((i) => i.unread).length));
    } catch (error) {
      emit(AlertsFailure(_messageFor(error)));
    }
  }

  Future<void> _onMarkAll(AllMarkedRead event, Emitter<AlertsState> emit) async {
    final current = state;
    if (current is! AlertsLoaded) return;
    try {
      await remoteDataSource.markAllRead();
      final items = current.items
          .map((i) => AlertItem(
              id: i.id, type: i.type, title: i.title, body: i.body,
              unread: false, refId: i.refId, createdAt: i.createdAt))
          .toList();
      emit(AlertsLoaded(items, unreadCount: 0));
    } catch (error) {
      emit(AlertsFailure(_messageFor(error)));
    }
  }

  String _messageFor(Object error) => switch (error) {
        NetworkException(:final message) => message,
        ServerException(:final message) => message,
        _ => 'Could not load alerts. Please try again.',
      };
}
