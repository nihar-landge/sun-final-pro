import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/errors/failures.dart';
import 'package:feedback_app/features/feedback/data/repositories/feedback_repository_impl.dart';
export 'package:feedback_app/features/feedback/domain/entities/feedback.dart'
    show FeedbackDetail, StatusChange;
import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';

/// Loads one report (comments + status history) and handles upvote/comment
/// on the detail screen.
sealed class DetailEvent extends Equatable {
  const DetailEvent();

  @override
  List<Object?> get props => [];
}

class DetailLoaded extends DetailEvent {
  final int feedbackId;

  const DetailLoaded(this.feedbackId);

  @override
  List<Object?> get props => [feedbackId];
}

class DetailUpvoteRequested extends DetailEvent {
  const DetailUpvoteRequested();
}

class DetailCommentSubmitted extends DetailEvent {
  final String text;

  const DetailCommentSubmitted(this.text);

  @override
  List<Object?> get props => [text];
}

sealed class DetailState extends Equatable {
  const DetailState();

  @override
  List<Object?> get props => [];
}

class DetailLoading extends DetailState {
  const DetailLoading();
}

class DetailReady extends DetailState {
  final FeedbackDetail detail;

  const DetailReady(this.detail);

  @override
  List<Object?> get props => [detail];
}

class DetailActionInProgress extends DetailState {
  final FeedbackDetail detail;

  const DetailActionInProgress(this.detail);

  @override
  List<Object?> get props => [detail];
}

class DetailMessage extends DetailState {
  final FeedbackDetail detail;
  final String message;

  const DetailMessage(this.detail, this.message);

  @override
  List<Object?> get props => [detail, message];
}

class DetailFailure extends DetailState {
  final String message;
  final FeedbackDetail? detail;

  const DetailFailure(this.message, [this.detail]);

  @override
  List<Object?> get props => [message, detail];
}


class FeedbackDetailBloc extends Bloc<DetailEvent, DetailState> {
  final FeedbackRepositoryImpl repository;
  final int feedbackId;

  FeedbackDetailBloc({
    required this.repository,
    required this.feedbackId,
  }) : super(const DetailLoading()) {
    on<DetailLoaded>(_onLoad);
    on<DetailUpvoteRequested>(_onUpvote);
    on<DetailCommentSubmitted>(_onComment);
  }

  Future<void> _onLoad(DetailLoaded event, Emitter<DetailState> emit) async {
    emit(const DetailLoading());
    await _load(emit);
  }

  Future<void> _load(Emitter<DetailState> emit) async {
    try {
      final data = await repository.getDetail(feedbackId);
      emit(DetailReady(data));
    } on Failure catch (failure) {
      emit(DetailFailure(failure.message));
    }
  }

  Future<void> _onUpvote(DetailUpvoteRequested event, Emitter<DetailState> emit) async {
    final current = state;
    if (current is! DetailReady) return;
    emit(DetailActionInProgress(current.detail));
    try {
      await repository.upvote(feedbackId);
      final data = await repository.getDetail(feedbackId);
      emit(DetailMessage(data, 'Thanks for supporting this report!'));
    } on Failure catch (failure) {
      final data = await _safeReload();
      emit(DetailMessage(data ?? current.detail, failure.message));
    }
  }

  Future<void> _onComment(DetailCommentSubmitted event, Emitter<DetailState> emit) async {
    final current = state;
    if (current is! DetailReady) return;
    emit(DetailActionInProgress(current.detail));
    try {
      await repository.addComment(feedbackId, event.text);
      final data = await repository.getDetail(feedbackId);
      emit(DetailMessage(data, 'Comment posted'));
    } on Failure catch (failure) {
      emit(DetailMessage(current.detail, failure.message));
    }
  }

  Future<FeedbackDetail?> _safeReload() async {
    try {
      return await repository.getDetail(feedbackId);
    } on Failure {
      return null;
    }
  }
}
