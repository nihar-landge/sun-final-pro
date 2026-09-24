import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/errors/failures.dart';
import 'package:feedback_app/features/feedback/data/repositories/feedback_repository_impl.dart';
import 'package:feedback_app/features/polls/domain/repositories/poll_repository.dart';

/// "Alerts" derived from real data the citizen can act on today:
///  · their own reports with the current status (tap → track progress)
///  · active polls closing within 24h (tap → vote)
/// FCM push items will prepend to the same list once notifications land.
sealed class AlertsEvent extends Equatable {
  const AlertsEvent();

  @override
  List<Object?> get props => [];
}

class AlertsRefreshed extends AlertsEvent {
  const AlertsRefreshed();
}

/// One alert row.
class AlertItem extends Equatable {
  final AlertKind kind;
  final String title;
  final String subtitle;
  final String? status;
  final DateTime? when;
  final int? reportId;
  final int? pollId;

  const AlertItem({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.status,
    this.when,
    this.reportId,
    this.pollId,
  });

  @override
  List<Object?> get props =>
      [kind, title, subtitle, status, when, reportId, pollId];
}

enum AlertKind { reportStatus, pollClosing, pollLive }

sealed class AlertsState extends Equatable {
  const AlertsState();

  @override
  List<Object?> get props => [];
}

class AlertsLoading extends AlertsState {
  const AlertsLoading();
}

class AlertsLoaded extends AlertsState {
  final List<AlertItem> items;

  const AlertsLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class AlertsFailure extends AlertsState {
  final String message;

  const AlertsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  final FeedbackRepositoryImpl feedbackRepository;
  final PollRepository pollRepository;

  AlertsBloc({
    required this.feedbackRepository,
    required this.pollRepository,
  }) : super(const AlertsLoading()) {
    on<AlertsRefreshed>(_onRefresh);
  }

  Future<void> _onRefresh(AlertsRefreshed event, Emitter<AlertsState> emit) async {
    emit(const AlertsLoading());
    try {
      final reports = await feedbackRepository.mine();
      final polls = await pollRepository.getPolls(status: 'active');

      final items = <AlertItem>[];
      for (final report in reports.take(10)) {
        items.add(AlertItem(
          kind: AlertKind.reportStatus,
          title: report.title,
          subtitle: switch (report.status.name) {
            'RESOLVED' => 'Your report has been resolved 🎉',
            'IN_REVIEW' => 'Your report is being reviewed',
            _ => 'Your report is open — awaiting review',
          },
          status: report.status.name,
          when: DateTime.tryParse(report.createdAt),
          reportId: report.id,
        ));
      }
      for (final poll in polls) {
        final closesIn = poll.endTime.difference(DateTime.now());
        if (closesIn.inHours <= 24 && !closesIn.isNegative) {
          items.add(AlertItem(
            kind: AlertKind.pollClosing,
            title: poll.title,
            subtitle:
                'Poll closes ${closesIn.inHours == 0 ? 'in less than an hour' : 'in ${closesIn.inHours}h'} — ${poll.totalVotes} votes so far',
            when: poll.endTime,
            pollId: poll.id,
          ));
        } else if (!poll.hasVoted) {
          items.add(AlertItem(
            kind: AlertKind.pollLive,
            title: poll.title,
            subtitle: 'New poll open — your vote matters',
            when: poll.startTime,
            pollId: poll.id,
          ));
        }
      }
      items.sort((a, b) =>
          (b.when ?? DateTime.now()).compareTo(a.when ?? DateTime.now()));
      emit(AlertsLoaded(items));
    } on Failure catch (failure) {
      emit(AlertsFailure(failure.message));
    }
  }
}
