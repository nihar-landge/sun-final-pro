import 'package:feedback_app/core/errors/exceptions.dart';
import 'package:feedback_app/core/errors/failures.dart';
import 'package:feedback_app/features/feedback/data/datasources/feedback_remote_data_source.dart';
import 'package:feedback_app/features/feedback/data/models/feedback_model.dart';
import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';

class FeedbackRepositoryImpl {
  final FeedbackRemoteDataSource remoteDataSource;

  FeedbackRepositoryImpl(this.remoteDataSource);

  Future<FeedbackItem> submit({
    required String title,
    required String description,
    required FeedbackCategory category,
    double? latitude,
    double? longitude,
  }) async {
    try {
      return await remoteDataSource.submit(
        title: title,
        description: description,
        category: category,
        latitude: latitude,
        longitude: longitude,
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }

  Future<List<FeedbackItem>> list({String? status}) async {
    try {
      return await remoteDataSource.list(status: status);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }

  Future<List<FeedbackItem>> mine() async {
    try {
      return await remoteDataSource.mine();
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }

  Future<List<FeedbackItem>> nearMe({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    try {
      return await remoteDataSource.nearMe(lat: lat, lng: lng, radiusKm: radiusKm);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }

  Future<void> upvote(int feedbackId) async {
    try {
      await remoteDataSource.upvote(feedbackId);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      final message =
          e.statusCode == 409 ? 'You have already upvoted this' : e.message;
      throw ServerFailure(message, statusCode: e.statusCode);
    }
  }

  Future<List<FeedbackComment>> getComments(int feedbackId) async {
    try {
      return await remoteDataSource.getComments(feedbackId);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }

  /// Community impact for the Home screen (public, no auth needed).
  Future<CommunityStats> communityStats() async {
    try {
      final data = await remoteDataSource.communityStats();
      return CommunityStats(
        totalReports: (data['totalReports'] as num? ?? 0).toInt(),
        resolvedReports: (data['resolvedReports'] as num? ?? 0).toInt(),
        resolutionRatePercent: (data['resolutionRatePercent'] as num? ?? 0).toInt(),
        totalUpvotes: (data['totalUpvotes'] as num? ?? 0).toInt(),
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }

  /// Uploads one photo in a single multipart request.
  Future<void> uploadPhoto(int feedbackId, FeedbackPhoto photo) async {
    try {
      await remoteDataSource.uploadPhoto(feedbackId, photo.bytes, photo.contentType);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }

  /// Full detail (item + comments + status history) for the detail screen.
  Future<FeedbackDetail> getDetail(int feedbackId) async {
    try {
      final data = await remoteDataSource.getDetail(feedbackId);
      final item = FeedbackModel.fromJson(data);
      final comments = (data['comments'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FeedbackModel.commentFromJson)
          .cast<FeedbackComment>()
          .toList();
      final history = (data['history'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((h) => StatusChange(
                oldStatus: h['oldStatus'] as String?,
                newStatus: h['newStatus'] as String? ?? '',
                changedAt: h['changedAt'] as String? ?? '',
              ))
          .cast<StatusChange>()
          .toList();
      final images = (data['images'] as List? ?? []).cast<String>().toList();
      return FeedbackDetail(
          item: item,
          comments: comments,
          history: history,
          images: images,
          publicNote: data['publicNote'] as String? ?? '');
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }

  Future<void> addComment(int feedbackId, String text) async {
    try {
      await remoteDataSource.addComment(feedbackId, text);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }
}
