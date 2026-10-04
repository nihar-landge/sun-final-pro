import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';

class FeedbackModel {
  const FeedbackModel._();

  static FeedbackItem fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: _category(json['category'] as String?),
      status: _status(json['status'] as String?),
      upvotes: (json['upvotes'] as num? ?? 0).toInt(),
      userId: (json['userId'] as num? ?? 0).toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  static FeedbackComment commentFromJson(Map<String, dynamic> json) {
    return FeedbackComment(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      text: json['text'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  static String wireCategory(FeedbackCategory category) => switch (category) {
        FeedbackCategory.roads => 'ROADS',
        FeedbackCategory.water => 'WATER',
        FeedbackCategory.electricity => 'ELECTRICITY',
        FeedbackCategory.sanitation => 'SANITATION',
        FeedbackCategory.transport => 'TRANSPORT',
        FeedbackCategory.other => 'OTHER',
      };

  static String wireStatus(FeedbackStatus status) => switch (status) {
        FeedbackStatus.open => 'OPEN',
        FeedbackStatus.inProgress => 'IN_PROGRESS',
        FeedbackStatus.resolved => 'RESOLVED',
      };

  static FeedbackCategory _category(String? value) => switch (value) {
        'ROADS' => FeedbackCategory.roads,
        'WATER' => FeedbackCategory.water,
        'ELECTRICITY' => FeedbackCategory.electricity,
        'SANITATION' => FeedbackCategory.sanitation,
        'TRANSPORT' => FeedbackCategory.transport,
        _ => FeedbackCategory.other,
      };

  static FeedbackStatus _status(String? value) => switch (value) {
        'IN_PROGRESS' => FeedbackStatus.inProgress,
        'RESOLVED' => FeedbackStatus.resolved,
        _ => FeedbackStatus.open,
      };
}
