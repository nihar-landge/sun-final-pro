import 'package:feedback_app/core/errors/exceptions.dart';
import 'package:feedback_app/core/errors/failures.dart';
import 'package:feedback_app/features/feedback/data/datasources/feedback_remote_data_source.dart';
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
