import 'package:feedback_app/core/errors/exceptions.dart';
import 'package:feedback_app/core/errors/failures.dart';
import 'package:feedback_app/features/polls/data/datasources/poll_remote_data_source.dart';
import 'package:feedback_app/features/polls/domain/entities/poll.dart';
import 'package:feedback_app/features/polls/domain/repositories/poll_repository.dart';

class PollRepositoryImpl implements PollRepository {
  final PollRemoteDataSource remoteDataSource;

  PollRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Poll>> getPolls({String status = 'active'}) async {
    try {
      return await remoteDataSource.listPolls(status: status);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }

  @override
  Future<Poll> getResults(int pollId) async {
    try {
      return await remoteDataSource.getResults(pollId);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }

  @override
  Future<Poll> vote(int pollId, int optionId) async {
    try {
      return await remoteDataSource.vote(pollId, optionId);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      final message = e.statusCode == 409
          ? 'You have already voted in this poll'
          : e.message;
      throw ServerFailure(message, statusCode: e.statusCode);
    }
  }
}
