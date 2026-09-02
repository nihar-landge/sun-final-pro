import 'package:feedback_app/features/polls/domain/entities/poll.dart';

abstract interface class PollRepository {
  Future<List<Poll>> getPolls({String status});

  Future<Poll> getResults(int pollId);

  Future<Poll> vote(int pollId, int optionId);
}
