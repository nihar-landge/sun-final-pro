import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/errors/failures.dart';
import 'package:feedback_app/features/feedback/data/repositories/feedback_repository_impl.dart';
import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';

// ---------- Events ----------

sealed class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object?> get props => [];
}

class FeedbackListRequested extends FeedbackEvent {
  final String? status;

  const FeedbackListRequested({this.status});

  @override
  List<Object?> get props => [status];
}

class NearbyFeedbackRequested extends FeedbackEvent {
  final double lat;
  final double lng;

  const NearbyFeedbackRequested({required this.lat, required this.lng});

  @override
  List<Object?> get props => [lat, lng];
}

class FeedbackSubmitted extends FeedbackEvent {
  final String title;
  final String description;
  final FeedbackCategory category;
  final double? latitude;
  final double? longitude;

  const FeedbackSubmitted({
    required this.title,
    required this.description,
    required this.category,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [title, description, category, latitude, longitude];
}

class UpvoteRequested extends FeedbackEvent {
  final int feedbackId;

  const UpvoteRequested(this.feedbackId);

  @override
  List<Object?> get props => [feedbackId];
}

// ---------- States ----------

sealed class FeedbackState extends Equatable {
  const FeedbackState();

  @override
  List<Object?> get props => [];
}

class FeedbackInitial extends FeedbackState {
  const FeedbackInitial();
}

class FeedbackLoading extends FeedbackState {
  final List<FeedbackItem> items;

  const FeedbackLoading([this.items = const []]);

  @override
  List<Object?> get props => [items];
}

class FeedbackLoaded extends FeedbackState {
  final List<FeedbackItem> items;
  final bool nearby; // true when the list is the near-me result

  const FeedbackLoaded(this.items, {this.nearby = false});

  @override
  List<Object?> get props => [items, nearby];
}

class FeedbackSubmitting extends FeedbackState {
  const FeedbackSubmitting();
}

class FeedbackActionSuccess extends FeedbackState {
  final List<FeedbackItem> items;
  final String message;

  const FeedbackActionSuccess(this.items, this.message);

  @override
  List<Object?> get props => [items, message];
}

class FeedbackFailure extends FeedbackState {
  final String message;

  const FeedbackFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// ---------- Bloc ----------

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final FeedbackRepositoryImpl repository;

  FeedbackBloc({required this.repository}) : super(const FeedbackInitial()) {
    on<FeedbackListRequested>(_onListRequested);
    on<NearbyFeedbackRequested>(_onNearbyRequested);
    on<FeedbackSubmitted>(_onSubmitted);
    on<UpvoteRequested>(_onUpvote);
  }

  List<FeedbackItem> _currentItems(FeedbackState state) => switch (state) {
        FeedbackLoaded s => s.items,
        FeedbackLoading s => s.items,
        FeedbackActionSuccess s => s.items,
        _ => const <FeedbackItem>[],
      };

  Future<void> _onListRequested(FeedbackListRequested event, Emitter<FeedbackState> emit) async {
    emit(FeedbackLoading(_currentItems(state)));
    try {
      final items = await repository.list(status: event.status);
      emit(FeedbackLoaded(items));
    } on Failure catch (failure) {
      emit(FeedbackFailure(failure.message));
    }
  }

  Future<void> _onNearbyRequested(NearbyFeedbackRequested event, Emitter<FeedbackState> emit) async {
    emit(FeedbackLoading(_currentItems(state)));
    try {
      final items = await repository.nearMe(lat: event.lat, lng: event.lng);
      emit(FeedbackLoaded(items, nearby: true));
    } on Failure catch (failure) {
      emit(FeedbackFailure(failure.message));
    }
  }

  Future<void> _onSubmitted(FeedbackSubmitted event, Emitter<FeedbackState> emit) async {
    emit(const FeedbackSubmitting());
    try {
      final created = await repository.submit(
        title: event.title,
        description: event.description,
        category: event.category,
        latitude: event.latitude,
        longitude: event.longitude,
      );
      final items = [..._currentItems(state), created];
      emit(FeedbackActionSuccess(items, 'Feedback submitted — thank you!'));
    } on Failure catch (failure) {
      emit(FeedbackFailure(failure.message));
    }
  }

  Future<void> _onUpvote(UpvoteRequested event, Emitter<FeedbackState> emit) async {
    try {
      await repository.upvote(event.feedbackId);
      final items = _currentItems(state)
          .map((f) => f.id == event.feedbackId
              ? FeedbackItem(
                  id: f.id, title: f.title, description: f.description,
                  category: f.category, status: f.status, upvotes: f.upvotes + 1,
                  latitude: f.latitude, longitude: f.longitude, createdAt: f.createdAt)
              : f)
          .toList();
      emit(FeedbackActionSuccess(items, 'Upvoted'));
    } on Failure catch (failure) {
      emit(FeedbackFailure(failure.message));
    }
  }
}
