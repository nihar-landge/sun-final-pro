import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_admin/core/api_client.dart';

/// KPI payload for the Analytics tab: poll participation, feedback stats and
/// the recent event feed consumed from RabbitMQ.
class AdminAnalytics extends Equatable {
  final PollStats pollStats;
  final FeedbackStats feedbackStats;
  final List<RecentEvent> events;

  const AdminAnalytics({
    required this.pollStats,
    required this.feedbackStats,
    required this.events,
  });

  @override
  List<Object?> get props => [pollStats, feedbackStats, events];
}

class PollStats extends Equatable {
  final int totalPolls;
  final int activePolls;
  final int totalVotes;
  final double avgVotesPerPoll;
  final String? topPollTitle;
  final int? topPollVotes;

  const PollStats({
    required this.totalPolls,
    required this.activePolls,
    required this.totalVotes,
    required this.avgVotesPerPoll,
    this.topPollTitle,
    this.topPollVotes,
  });

  factory PollStats.fromJson(Map<String, dynamic> json) {
    final top = json['topPoll'];
    return PollStats(
      totalPolls: (json['totalPolls'] as num? ?? 0).toInt(),
      activePolls: (json['activePolls'] as num? ?? 0).toInt(),
      totalVotes: (json['totalVotes'] as num? ?? 0).toInt(),
      avgVotesPerPoll: (json['avgVotesPerPoll'] as num? ?? 0).toDouble(),
      topPollTitle: top is Map<String, dynamic> ? top['title'] as String? : null,
      topPollVotes: top is Map<String, dynamic> ? (top['totalVotes'] as num?)?.toInt() : null,
    );
  }

  @override
  List<Object?> get props =>
      [totalPolls, activePolls, totalVotes, avgVotesPerPoll, topPollTitle, topPollVotes];
}

class FeedbackStats extends Equatable {
  final int totalFeedback;
  final Map<String, int> byStatus;
  final Map<String, int> byCategory;
  final double? avgResolutionHours;
  final int submittedLast7Days;

  const FeedbackStats({
    required this.totalFeedback,
    required this.byStatus,
    required this.byCategory,
    this.avgResolutionHours,
    required this.submittedLast7Days,
  });

  factory FeedbackStats.fromJson(Map<String, dynamic> json) {
    int mapInt(Object? v) => (v as num? ?? 0).toInt();
    final byStatus = <String, int>{};
    (json['byStatus'] as Map<String, dynamic>? ?? {}).forEach((k, v) => byStatus[k] = mapInt(v));
    final byCategory = <String, int>{};
    (json['byCategory'] as Map<String, dynamic>? ?? {}).forEach((k, v) => byCategory[k] = mapInt(v));
    return FeedbackStats(
      totalFeedback: mapInt(json['totalFeedback']),
      byStatus: byStatus,
      byCategory: byCategory,
      avgResolutionHours: (json['avgResolutionHours'] as num?)?.toDouble(),
      submittedLast7Days: mapInt(json['submittedLast7Days']),
    );
  }

  @override
  List<Object?> get props => [totalFeedback, byStatus, byCategory, avgResolutionHours, submittedLast7Days];
}

class RecentEvent extends Equatable {
  final String type;
  final String title;
  final String? oldStatus;
  final String? newStatus;
  final String occurredAt;

  const RecentEvent({
    required this.type,
    required this.title,
    this.oldStatus,
    this.newStatus,
    required this.occurredAt,
  });

  factory RecentEvent.fromJson(Map<String, dynamic> json) => RecentEvent(
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        oldStatus: json['oldStatus'] as String?,
        newStatus: json['newStatus'] as String?,
        occurredAt: json['occurredAt'] as String? ?? '',
      );

  @override
  List<Object?> get props => [type, title, oldStatus, newStatus, occurredAt];
}

sealed class AdminAnalyticsEvent extends Equatable {
  const AdminAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class AdminAnalyticsRefreshed extends AdminAnalyticsEvent {
  const AdminAnalyticsRefreshed();
}

sealed class AdminAnalyticsState extends Equatable {
  const AdminAnalyticsState();

  @override
  List<Object?> get props => [];
}

class AdminAnalyticsLoading extends AdminAnalyticsState {
  const AdminAnalyticsLoading();
}

class AdminAnalyticsLoaded extends AdminAnalyticsState {
  final AdminAnalytics analytics;

  const AdminAnalyticsLoaded(this.analytics);

  @override
  List<Object?> get props => [analytics];
}

class AdminAnalyticsFailure extends AdminAnalyticsState {
  final String message;

  const AdminAnalyticsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminAnalyticsBloc extends Bloc<AdminAnalyticsEvent, AdminAnalyticsState> {
  final AdminApiClient apiClient;

  AdminAnalyticsBloc({required this.apiClient}) : super(const AdminAnalyticsLoading()) {
    on<AdminAnalyticsRefreshed>(_onRefresh);
    add(const AdminAnalyticsRefreshed());
  }

  Future<void> _onRefresh(AdminAnalyticsRefreshed event, Emitter<AdminAnalyticsState> emit) async {
    emit(const AdminAnalyticsLoading());
    try {
      final pollStats = PollStats.fromJson(
          await apiClient.request('/polls/analytics/summary'));
      final feedbackStats = FeedbackStats.fromJson(
          await apiClient.request('/feedback/analytics/summary'));
      final eventsData = await apiClient.request('/notifications/recent');
      final events = (eventsData as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RecentEvent.fromJson)
          .toList();
      emit(AdminAnalyticsLoaded(AdminAnalytics(
        pollStats: pollStats, feedbackStats: feedbackStats, events: events)));
    } on AdminApiException catch (e) {
      emit(AdminAnalyticsFailure(e.message));
    }
  }
}
