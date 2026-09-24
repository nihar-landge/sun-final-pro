import 'package:equatable/equatable.dart';

enum FeedbackCategory { roads, water, electricity, sanitation, transport, other }

enum FeedbackStatus { open, inReview, resolved }

class FeedbackItem extends Equatable {
  final int id;
  final String title;
  final String description;
  final FeedbackCategory category;
  final FeedbackStatus status;
  final int upvotes;
  final int userId;
  final double? latitude;
  final double? longitude;
  final String createdAt;

  const FeedbackItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.upvotes,
    this.userId = 0,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, title, description, category, status, upvotes, userId, latitude, longitude, createdAt];
}

class FeedbackComment extends Equatable {
  final int id;
  final int userId;
  final String text;
  final String createdAt;

  const FeedbackComment({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, text, createdAt];
}


/// Flat view of the report detail payload (item + comments + history).
class FeedbackDetail extends Equatable {
  final FeedbackItem item;
  final List<FeedbackComment> comments;
  final List<StatusChange> history;

  const FeedbackDetail({
    required this.item,
    required this.comments,
    required this.history,
  });

  @override
  List<Object?> get props => [item, comments, history];
}

/// One audited status transition.
class StatusChange extends Equatable {
  final String? oldStatus;
  final String newStatus;
  final String changedAt;

  const StatusChange({
    required this.oldStatus,
    required this.newStatus,
    required this.changedAt,
  });

  @override
  List<Object?> get props => [oldStatus, newStatus, changedAt];
}
