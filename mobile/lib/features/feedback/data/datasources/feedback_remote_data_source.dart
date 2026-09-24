import 'package:feedback_app/core/constants/api_constants.dart';
import 'package:feedback_app/core/network/api_client.dart';
import 'package:feedback_app/features/feedback/data/models/feedback_model.dart';
import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';

/// Talks to feedback-service through the API gateway.
class FeedbackRemoteDataSource {
  final ApiClient apiClient;

  FeedbackRemoteDataSource(this.apiClient);

  Future<FeedbackItem> submit({
    required String title,
    required String description,
    required FeedbackCategory category,
    double? latitude,
    double? longitude,
  }) async {
    final data = await apiClient.post(
      Uri.parse(ApiConstants.feedbackBase),
      body: {
        'title': title,
        'description': description,
        'category': FeedbackModel.wireCategory(category),
        'latitude': ?latitude,
        'longitude': ?longitude,
      },
      authenticated: true,
    );
    return FeedbackModel.fromJson(data);
  }

  Future<List<FeedbackItem>> list({String? status}) async {
    final query = status == null ? '' : '?status=$status';
    final data = await apiClient.getDynamic(
      Uri.parse('${ApiConstants.feedbackBase}$query'),
      authenticated: true,
    );
    return _itemsFrom(data);
  }

  /// The signed-in citizen's own reports, newest first.
  Future<List<FeedbackItem>> mine() async {
    final data = await apiClient.getDynamic(
      Uri.parse('${ApiConstants.feedbackBase}/mine'),
      authenticated: true,
    );
    return _itemsFrom(data);
  }

  List<FeedbackItem> _itemsFrom(dynamic data) {
    final content = data is Map<String, dynamic> ? data['content'] : data;
    return content is List
        ? content.whereType<Map<String, dynamic>>().map(FeedbackModel.fromJson).toList()
        : <FeedbackItem>[];
  }

  Future<List<FeedbackItem>> nearMe({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    final data = await apiClient.getDynamic(
      Uri.parse('${ApiConstants.feedbackBase}/near-me?lat=$lat&lng=$lng&radiusKm=$radiusKm'),
      authenticated: true,
    );
    return data is List
        ? data.whereType<Map<String, dynamic>>().map(FeedbackModel.fromJson).toList()
        : <FeedbackItem>[];
  }

  Future<void> upvote(int feedbackId) async {
    await apiClient.post(
      Uri.parse('${ApiConstants.feedbackBase}/$feedbackId/upvote'),
      authenticated: true,
    );
  }

  /// Raw detail payload (item + comments + history) for the repository.
  Future<Map<String, dynamic>> getDetail(int feedbackId) {
    return apiClient.get(
      Uri.parse('${ApiConstants.feedbackBase}/$feedbackId'),
      authenticated: true,
    );
  }

  Future<List<FeedbackComment>> getComments(int feedbackId) async {
    final data = await apiClient.get(
      Uri.parse('${ApiConstants.feedbackBase}/$feedbackId'),
      authenticated: true,
    );
    final comments = data['comments'];
    return comments is List
        ? comments.whereType<Map<String, dynamic>>().map(FeedbackModel.commentFromJson).toList()
        : <FeedbackComment>[];
  }

  Future<void> addComment(int feedbackId, String text) async {
    await apiClient.post(
      Uri.parse('${ApiConstants.feedbackBase}/$feedbackId/comments'),
      body: {'text': text},
      authenticated: true,
    );
  }
}
