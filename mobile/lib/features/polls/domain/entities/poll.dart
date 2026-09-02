import 'package:equatable/equatable.dart';

/// Domain entity for a poll with its options and (when available) results.
class Poll extends Equatable {
  final int id;
  final String title;
  final String description;
  final String status; // SCHEDULED | ACTIVE | CLOSED
  final bool anonymous;
  final DateTime startTime;
  final DateTime endTime;
  final int totalVotes;
  final bool hasVoted; // whether the current user already voted
  final List<PollOptionResult> options;

  const Poll({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.anonymous,
    required this.startTime,
    required this.endTime,
    required this.totalVotes,
    this.hasVoted = false,
    required this.options,
  });

  bool get isActive => status == 'ACTIVE';

  @override
  List<Object?> get props => [id, title, description, status, anonymous, startTime, endTime,
        totalVotes, hasVoted, options];
}

class PollOptionResult extends Equatable {
  final int optionId;
  final String text;
  final int votes;
  final double percentage;

  const PollOptionResult({
    required this.optionId,
    required this.text,
    required this.votes,
    required this.percentage,
  });

  @override
  List<Object?> get props => [optionId, text, votes, percentage];
}
