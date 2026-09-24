import 'package:feedback_app/features/polls/domain/entities/poll.dart';

class PollModel {
  const PollModel._();

  /// Parses the poll detail/results payload from poll-service.
  static Poll fromJson(Map<String, dynamic> json) {
    final results = json['results'];
    final options = results is List
        ? results
            .whereType<Map<String, dynamic>>()
            .map(PollModel._optionFromJson)
            .toList()
        : <PollOptionResult>[];
    return Poll(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'CLOSED',
      anonymous: json['anonymous'] as bool? ?? false,
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime'] as String? ?? '') ?? DateTime.now(),
      totalVotes: (json['totalVotes'] as num? ?? 0).toInt(),
      hasVoted: json['hasVoted'] as bool? ?? false,
      options: options,
    );
  }

  /// Parses the poll summary payload (list endpoints; now carries a
  /// result preview so cards can render percentage bars).
  static Poll summaryFromJson(Map<String, dynamic> json) {
    final results = json['results'];
    final options = results is List
        ? results
            .whereType<Map<String, dynamic>>()
            .map(PollModel._optionFromJson)
            .toList()
        : <PollOptionResult>[];
    return Poll(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'CLOSED',
      anonymous: false,
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime'] as String? ?? '') ?? DateTime.now(),
      totalVotes: (json['totalVotes'] as num? ?? 0).toInt(),
      options: options,
    );
  }

  static PollOptionResult _optionFromJson(Map<String, dynamic> json) {
    return PollOptionResult(
      optionId: (json['optionId'] as num).toInt(),
      text: json['text'] as String? ?? '',
      votes: (json['votes'] as num? ?? 0).toInt(),
      percentage: (json['percentage'] as num? ?? 0).toDouble(),
    );
  }
}
