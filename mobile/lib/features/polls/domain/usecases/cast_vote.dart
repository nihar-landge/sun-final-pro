import 'package:feedback_app/features/polls/domain/entities/poll.dart';
import 'package:feedback_app/features/polls/domain/repositories/poll_repository.dart';

class CastVote {
  final PollRepository repository;

  CastVote(this.repository);

  Future<Poll> call({required int pollId, required int optionId}) =>
      repository.vote(pollId, optionId);
}
