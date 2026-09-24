import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/errors/failures.dart';
import 'package:feedback_app/features/polls/domain/entities/poll.dart';
import 'package:feedback_app/features/polls/domain/repositories/poll_repository.dart';
import 'package:feedback_app/features/polls/domain/usecases/cast_vote.dart';
import 'package:feedback_app/features/polls/domain/usecases/get_active_polls.dart';
import 'package:feedback_app/features/polls/domain/usecases/get_poll_results.dart';

// ---------- Events ----------

sealed class PollsEvent extends Equatable {
  const PollsEvent();

  @override
  List<Object?> get props => [];
}

class PollsRequested extends PollsEvent {
  final String status;

  const PollsRequested({this.status = 'active'});

  @override
  List<Object?> get props => [status];
}

class VoteRequested extends PollsEvent {
  final int pollId;
  final int optionId;

  const VoteRequested({required this.pollId, required this.optionId});

  @override
  List<Object?> get props => [pollId, optionId];
}

class PollResultsRefreshed extends PollsEvent {
  final int pollId;

  const PollResultsRefreshed(this.pollId);

  @override
  List<Object?> get props => [pollId];
}

/// Pushed by the WebSocket subscription on the poll detail page.
class PollLiveUpdate extends PollsEvent {
  final Poll poll;

  const PollLiveUpdate(this.poll);

  @override
  List<Object?> get props => [poll];
}

// ---------- States ----------

sealed class PollsState extends Equatable {
  const PollsState();

  @override
  List<Object?> get props => [];
}

class PollsInitial extends PollsState {
  const PollsInitial();
}

class PollsLoading extends PollsState {
  const PollsLoading();
}

class PollsLoaded extends PollsState {
  final List<Poll> polls;

  const PollsLoaded(this.polls);

  @override
  List<Object?> get props => [polls];
}

class PollVoting extends PollsState {
  final List<Poll> polls;

  const PollVoting(this.polls);

  @override
  List<Object?> get props => [polls];
}

class VoteRecorded extends PollsState {
  final Poll poll; // updated poll with fresh results
  final List<Poll> polls; // list snapshot so the list page never goes blank

  const VoteRecorded(this.poll, [this.polls = const []]);

  @override
  List<Object?> get props => [poll, polls];
}

class PollsFailure extends PollsState {
  final String message;
  final List<Poll> polls;

  const PollsFailure(this.message, [this.polls = const []]);

  @override
  List<Object?> get props => [message, polls];
}

// ---------- Bloc ----------

class PollsBloc extends Bloc<PollsEvent, PollsState> {
  final GetActivePolls getActivePolls;
  final CastVote castVote;
  final GetPollResults getPollResults;

  PollsBloc({required PollRepository repository})
      : getActivePolls = GetActivePolls(repository),
        castVote = CastVote(repository),
        getPollResults = GetPollResults(repository),
        super(const PollsInitial()) {
    on<PollsRequested>(_onPollsRequested);
    on<VoteRequested>(_onVoteRequested);
    on<PollResultsRefreshed>(_onResultsRefreshed);
    on<PollLiveUpdate>(_onLiveUpdate);
  }

  /// The latest known poll list, preserved across vote/failure states so the
  /// list page never shows an empty screen after an action.
  List<Poll> _currentPolls(PollsState state) => switch (state) {
        PollsLoaded s => s.polls,
        PollVoting s => s.polls,
        VoteRecorded s => s.polls,
        PollsFailure s => s.polls,
        _ => const <Poll>[],
      };

  Future<void> _onPollsRequested(PollsRequested event, Emitter<PollsState> emit) async {
    emit(const PollsLoading());
    try {
      final polls = await getActivePolls(status: event.status);
      emit(PollsLoaded(polls));
    } on Failure catch (failure) {
      emit(PollsFailure(failure.message, _currentPolls(state)));
    }
  }

  Future<void> _onVoteRequested(VoteRequested event, Emitter<PollsState> emit) async {
    emit(PollVoting(_currentPolls(state)));
    try {
      final updated = await castVote(pollId: event.pollId, optionId: event.optionId);
      emit(VoteRecorded(updated, _currentPolls(state)));
    } on Failure catch (failure) {
      emit(PollsFailure(failure.message, _currentPolls(state)));
    }
  }

  Future<void> _onResultsRefreshed(PollResultsRefreshed event, Emitter<PollsState> emit) async {
    try {
      final poll = await getPollResults(event.pollId);
      emit(VoteRecorded(poll, _currentPolls(state)));
    } on Failure catch (failure) {
      emit(PollsFailure(failure.message, _currentPolls(state)));
    }
  }

  /// WebSocket push — no request needed, just swap the poll into state.
  Future<void> _onLiveUpdate(PollLiveUpdate event, Emitter<PollsState> emit) async {
    if (state is VoteRecorded && (state as VoteRecorded).poll.id == event.poll.id) {
      emit(VoteRecorded(event.poll, _currentPolls(state)));
    }
  }
}
