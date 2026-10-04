import 'dart:io';
import 'dart:typed_data';

import 'package:feedback_app/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:feedback_app/core/errors/exceptions.dart';
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

  /// Uploads one photo in a single multipart request to feedback-service.
  Future<void> uploadPhoto(int feedbackId, Uint8List bytes, String contentType) async {
    final accessToken = await apiClient.tokenStore?.readAccessToken() ?? '';
    final uri = Uri.parse('${ApiConstants.feedbackBase}/$feedbackId/photos');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'photo.${contentType.split('/').last == 'jpeg' ? 'jpg' : contentType.split('/').last}',
        contentType: MediaType.parse(contentType),
      ));
    try {
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      throw ServerException('Photo upload failed', statusCode: response.statusCode);
    } on SocketException {
      throw NetworkException('Could not reach the server. Check your connection.');
    }
  }

  /// Public community-impact numbers for the Home screen.
  Future<Map<String, dynamic>> communityStats() {
    return apiClient.get(
      Uri.parse('${ApiConstants.feedbackBase}/community-stats'),
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
