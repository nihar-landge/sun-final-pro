import 'package:feedback_app/features/polls/domain/entities/poll.dart';
import 'package:feedback_app/features/polls/domain/repositories/poll_repository.dart';

class GetActivePolls {
  final PollRepository repository;

  GetActivePolls(this.repository);

  Future<List<Poll>> call({String status = 'active'}) =>
      repository.getPolls(status: status);
}
