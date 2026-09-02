import 'package:feedback_app/core/constants/api_constants.dart';
import 'package:feedback_app/core/network/api_client.dart';
import 'package:feedback_app/features/polls/data/models/poll_model.dart';
import 'package:feedback_app/features/polls/domain/entities/poll.dart';

/// Talks to poll-service through the API gateway.
class PollRemoteDataSource {
  final ApiClient apiClient;

  PollRemoteDataSource(this.apiClient);

  Future<List<Poll>> listPolls({String status = 'active'}) async {
    final data = await apiClient.getDynamic(
      Uri.parse('${ApiConstants.pollsBase}?status=$status'),
      authenticated: true,
    );
    return data is List
        ? data.whereType<Map<String, dynamic>>().map(PollModel.summaryFromJson).toList()
        : <Poll>[];
  }

  Future<Poll> getResults(int pollId) async {
    final data = await apiClient.get(
      Uri.parse('${ApiConstants.pollsBase}/$pollId/results'),
      authenticated: true,
    );
    return PollModel.fromJson(data);
  }

  Future<Poll> vote(int pollId, int optionId) async {
    final data = await apiClient.post(
      Uri.parse('${ApiConstants.pollsBase}/$pollId/vote'),
      body: {'optionId': optionId},
      authenticated: true,
    );
    return PollModel.fromJson(data);
  }
}
