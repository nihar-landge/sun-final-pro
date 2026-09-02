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
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, title, description, category, status, upvotes, latitude, longitude, createdAt];
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
