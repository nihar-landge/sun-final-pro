import 'package:flutter/widgets.dart';

import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';
import 'package:feedback_app/l10n/gen/app_localizations.dart';

/// Localized labels for wire enum values shared across screens.

String feedbackStatusLabel(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context);
  return switch (status) {
    'OPEN' => l10n.statusOpen,
    'IN_REVIEW' => l10n.statusInReview,
    'RESOLVED' => l10n.statusResolved,
    _ => status,
  };
}

String feedbackCategoryLabel(BuildContext context, FeedbackCategory category) {
  final l10n = AppLocalizations.of(context);
  return switch (category) {
    FeedbackCategory.roads => l10n.categoryRoads,
    FeedbackCategory.water => l10n.categoryWater,
    FeedbackCategory.electricity => l10n.categoryElectricity,
    FeedbackCategory.sanitation => l10n.categorySanitation,
    FeedbackCategory.transport => l10n.categoryTransport,
    FeedbackCategory.other => l10n.categoryOther,
  };
}

String pollStatusLabel(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context);
  return switch (status) {
    'ACTIVE' => l10n.pollStatusLive,
    'SCHEDULED' => l10n.pollStatusUpcoming,
    _ => l10n.pollStatusClosed,
  };
}
