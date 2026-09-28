// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Your voice. Your community. Your impact.';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonSomethingWentWrong => 'Something went wrong';

  @override
  String get commonView => 'VIEW';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusInReview => 'In Review';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get categoryRoads => 'Roads';

  @override
  String get categoryWater => 'Water';

  @override
  String get categoryElectricity => 'Electricity';

  @override
  String get categorySanitation => 'Sanitation';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryOther => 'Other';

  @override
  String get pollStatusLive => 'LIVE';

  @override
  String get pollStatusUpcoming => 'UPCOMING';

  @override
  String get pollStatusClosed => 'CLOSED';

  @override
  String get pollVotedBadge => 'VOTED';

  @override
  String get pollEnded => 'Ended';

  @override
  String pollEndsInDays(int days) {
    return 'Ends in ${days}d';
  }

  @override
  String pollEndsInHours(int hours) {
    return 'Ends in ${hours}h';
  }

  @override
  String pollEndsInMinutes(int minutes) {
    return 'Ends in ${minutes}m';
  }

  @override
  String pollVotesCount(int count) {
    return '$count votes';
  }

  @override
  String pollParticipating(int count) {
    return '$count participating';
  }

  @override
  String pollParticipatingWithCountdown(int count, String countdown) {
    return '$count participating  •  $countdown';
  }

  @override
  String pollOptionsWithCountdown(int count, String countdown) {
    return '$count options · $countdown';
  }

  @override
  String get profileFallbackName => 'Citizen';

  @override
  String get profileSectionActivity => 'My activity';

  @override
  String get profileReportsFiled => 'reports filed';

  @override
  String profileViewAllReports(int count) {
    return 'View all $count reports';
  }

  @override
  String get profileSectionPreferences => 'Preferences';

  @override
  String get profileTheme => 'Theme';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileSectionPrivacy => 'Privacy';

  @override
  String get profileAnonymousVotingTitle => 'Anonymous voting';

  @override
  String get profileAnonymousVotingSubtitle =>
      'Your votes are always anonymous by design — results can never be traced back to you.';

  @override
  String get profileLocationSharingTitle => 'Location sharing';

  @override
  String get profileLocationSharingSubtitle =>
      'Only attached to a report when you choose to.';

  @override
  String get profileSectionAbout => 'About';

  @override
  String profileAboutSubtitle(String tagline) {
    return '$tagline\nCDAC Final Project — Mobile Computing';
  }

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get loginSubtitle =>
      'Raise your voice for your city.\nSign in with your phone number.';

  @override
  String get loginPhoneLabel => 'Phone number';

  @override
  String get loginSendOtp => 'Send OTP';

  @override
  String get otpTitle => 'Verify OTP';

  @override
  String otpSentTo(String phone) {
    return 'We sent a code to $phone';
  }

  @override
  String otpDevChip(String code) {
    return 'Dev OTP: $code — tap to fill';
  }

  @override
  String get otpCodeLabel => '6-digit OTP';

  @override
  String get otpNameLabel => 'Your name (new users)';

  @override
  String get otpVerifySignIn => 'Verify & Sign in';

  @override
  String get validationEnterPhone => 'Enter your phone number';

  @override
  String get validationPhoneDigits => 'Phone must be 10-15 digits';

  @override
  String get validationEnterOtp => 'Enter the OTP';

  @override
  String get validationOtpDigits => 'OTP must be 6 digits';

  @override
  String get validationEnterName => 'Enter your name';

  @override
  String get validationNameLength => 'Name must be at most 100 characters';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeSubtitle => 'Make your city better.';

  @override
  String get homeActivePoll => 'Active poll';

  @override
  String get homeQuickActions => 'Quick actions';

  @override
  String get homeQuickReport => 'Report\nIssue';

  @override
  String get homeQuickNearby => 'Nearby\nIssues';

  @override
  String get homeQuickPolls => 'Active\nPolls';

  @override
  String get homeQuickMyReports => 'My\nReports';

  @override
  String get homeNearbyIssues => 'Nearby issues';

  @override
  String get homeNoNearbyTitle => 'No nearby reports';

  @override
  String get homeNoNearbySubtitle =>
      'Your area looks clean — or be the first to report.';

  @override
  String get homeYourReports => 'Your reports';

  @override
  String get homeNoReports =>
      'You haven\'t reported anything yet.\nSpotted a problem? Tap + to report it.';

  @override
  String get homeCommunityImpact => 'Community impact';

  @override
  String get homeIssuesReported => 'issues reported';

  @override
  String get homeResolved => 'resolved';

  @override
  String get homeResolutionRate => 'resolution rate';

  @override
  String get mapTitle => 'Issues Near You';

  @override
  String get mapRecenter => 'Center on my location';

  @override
  String mapReportsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports',
      one: '1 report',
    );
    return '$_temp0';
  }

  @override
  String get mapViewReport => 'View Report';

  @override
  String get commonBack => 'Back';

  @override
  String get commonContinue => 'Continue';

  @override
  String get wizardTitle => 'Report an Issue';

  @override
  String get wizardSubmitReport => 'Submit Report';

  @override
  String get wizardCategoryQuestion => 'What is the problem?';

  @override
  String get wizardCategoryRoads => 'Roads';

  @override
  String get wizardCategoryStreetLights => 'Street Lights';

  @override
  String get wizardCategoryWaste => 'Waste';

  @override
  String get wizardCategoryWater => 'Water';

  @override
  String get wizardCategoryTraffic => 'Traffic';

  @override
  String get wizardCategoryPublicSpaces => 'Public Spaces';

  @override
  String get wizardDescribeTitle => 'What\'s happening?';

  @override
  String get wizardTitleHint =>
      'Short title, e.g. \"Large pothole near the bus stop\"';

  @override
  String get wizardDescriptionHint =>
      'Describe the issue — what, where exactly, since when…';

  @override
  String get wizardAddPhotos => 'Add photos';

  @override
  String get wizardPhotosHint =>
      'Up to 3 photos — clear photos get reports fixed faster.';

  @override
  String get wizardTakePhoto => 'Take a photo';

  @override
  String get wizardChooseGallery => 'Choose from gallery';

  @override
  String get wizardPickPhotoError => 'Could not pick the photo — try again.';

  @override
  String get wizardUploadingPhotos => 'Uploading photos…';

  @override
  String get wizardLocationQuestion => 'Where is the issue?';

  @override
  String get wizardNoLocationYet => 'No location set yet';

  @override
  String get wizardUseMyLocation => 'Use my current location';

  @override
  String get wizardManualEntryTitle => 'No GPS? Enter coordinates manually';

  @override
  String get wizardLatitude => 'Latitude';

  @override
  String get wizardLongitude => 'Longitude';

  @override
  String get wizardInvalid => 'Invalid';

  @override
  String get wizardLocationNote =>
      'Your location is used only for this report and helps the municipality find and fix the issue faster. You can copy coordinates from any maps app.';

  @override
  String get wizardLocationBlocked => 'Location is blocked for this app.';

  @override
  String get wizardOpenSettings => 'Open Settings';

  @override
  String get wizardLocationDenied =>
      'Location permission denied — enter coordinates below.';

  @override
  String get wizardLocationFailed =>
      'Could not get your location. Enter coordinates below.';

  @override
  String get wizardSimilarTitle => 'Similar reports nearby';

  @override
  String get wizardSimilarSubtitle =>
      'Reports within 300 m of your location, same category.';

  @override
  String get wizardCheckingNearby => 'Checking nearby reports…';

  @override
  String get wizardNoSimilarTitle => 'No similar reports';

  @override
  String get wizardNoSimilarSubtitle =>
      'You seem to be the first to spot this here.';

  @override
  String wizardSimilarFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'We found $count similar reports nearby. Supporting an existing report gets it fixed faster.',
      one:
          'We found 1 similar report nearby. Supporting an existing report gets it fixed faster.',
    );
    return '$_temp0';
  }

  @override
  String get wizardSimilarDistance => '<300 m';

  @override
  String get wizardStillFileReport =>
      'Still want to file your report? Submit below — more reports raise priority.';

  @override
  String get wizardSubmittedTitle => 'Report submitted!';

  @override
  String wizardSubmittedTrack(int id) {
    return 'Report #$id · track it from Alerts or Profile';
  }

  @override
  String get wizardTrackReport => 'Track your report';

  @override
  String get wizardBackHome => 'Back to home';

  @override
  String get detailTitle => 'Report';

  @override
  String get detailCitizen => 'Citizen';

  @override
  String detailUpvoteSupport(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people support this',
      one: '1 person supports this',
    );
    return '$_temp0';
  }

  @override
  String get detailOfficialUpdate => 'OFFICIAL UPDATE';

  @override
  String get detailResolvedTitle => '🎉 Issue Resolved';

  @override
  String get detailResolvedSubtitle =>
      'Your report helped bring attention to this issue.';

  @override
  String detailResolvedDates(
    String reported,
    String resolved,
    String duration,
  ) {
    return 'Reported $reported · Resolved $resolved · $duration';
  }

  @override
  String get detailSameDay => 'same day';

  @override
  String detailDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String detailCitizensSupported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count citizens supported this report',
      one: '1 citizen supported this report',
    );
    return '$_temp0';
  }

  @override
  String get detailProgress => 'Progress';

  @override
  String get detailLocation => 'Location';

  @override
  String detailComments(int count) {
    return 'Comments ($count)';
  }

  @override
  String get detailNoComments => 'No comments yet — start the conversation.';

  @override
  String get detailTimelineSubmitted => 'Report submitted';

  @override
  String get detailTimelineResolution => 'Resolution';

  @override
  String get detailTimelineReview => 'Review';

  @override
  String detailCitizenNumber(String id) {
    return 'Citizen #$id';
  }

  @override
  String get detailCommentHint => 'Write a comment…';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get pollsTitle => 'Polls';

  @override
  String get pollsSegmentActive => 'Active';

  @override
  String get pollsSegmentUpcoming => 'Upcoming';

  @override
  String get pollsSegmentClosed => 'Closed';

  @override
  String get pollsPullToRefresh => 'Pull down to refresh.';

  @override
  String get pollsEmptyActive => 'No active polls right now';

  @override
  String get pollsEmptyUpcoming => 'No upcoming polls scheduled';

  @override
  String get pollsEmptyClosed => 'No closed polls yet';

  @override
  String get pollDetailTitle => 'Poll';

  @override
  String get pollOpenUntil => 'open until';

  @override
  String get pollClosedLabel => 'closed';

  @override
  String get pollAnonymousSuffix => ' · anonymous';

  @override
  String get pollCastVote => 'Cast vote';

  @override
  String get pollAlreadyVoted =>
      'You already voted in this poll — thanks for participating!';

  @override
  String get pollLiveResults => 'Live results';

  @override
  String get pollResults => 'Results';

  @override
  String get pollInsights => 'Poll insights';

  @override
  String get pollTopChoice => 'Top choice';

  @override
  String get pollParticipation => 'Participation';

  @override
  String get pollEnds => 'Poll ends';

  @override
  String pollCitizensCount(int count) {
    return '$count citizens';
  }

  @override
  String pollEndsInDaysHours(int days, int hours) {
    return 'Ends in ${days}d ${hours}h';
  }

  @override
  String get pollRefreshResults => 'Refresh results';

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get alertsMarkAllRead => 'Mark all read';

  @override
  String get alertsNothingNew => 'Nothing new';

  @override
  String get alertsNothingNewSubtitle =>
      'Report an issue or vote in a poll to see updates here.';

  @override
  String get alertsToday => 'Today';

  @override
  String get alertsYesterday => 'Yesterday';

  @override
  String get alertsThisWeek => 'This week';

  @override
  String get alertsEarlier => 'Earlier';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutWhatYouCanDo => 'What you can do';

  @override
  String get aboutBulletPolls =>
      'Participate in public polls with live results';

  @override
  String get aboutBulletReports =>
      'Report local issues with photos and GPS location';

  @override
  String get aboutBulletSimilar => 'Find and support similar reports nearby';

  @override
  String get aboutBulletResolution =>
      'Track issue resolution with official updates';

  @override
  String get aboutBulletNotifications =>
      'Receive push notifications on status changes';

  @override
  String get aboutBuiltWith => 'Built with';

  @override
  String get aboutFooter =>
      'CDAC Final Project — Mobile Computing\nMicroservices · Clean Architecture · One person, one vote';
}
