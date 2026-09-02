import 'package:feedback_app/features/polls/domain/entities/poll.dart';
import 'package:feedback_app/features/polls/domain/repositories/poll_repository.dart';

class GetPollResults {
  final PollRepository repository;

  GetPollResults(this.repository);

  Future<Poll> call(int pollId) => repository.getResults(pollId);
}
