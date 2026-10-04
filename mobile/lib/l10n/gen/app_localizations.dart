import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your voice. Your community. Your impact.'**
  String get appTagline;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWentWrong;

  /// No description provided for @commonView.
  ///
  /// In en, this message translates to:
  /// **'VIEW'**
  String get commonView;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPolls.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get navPolls;

  /// No description provided for @navReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get navReport;

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @categoryRoads.
  ///
  /// In en, this message translates to:
  /// **'Roads'**
  String get categoryRoads;

  /// No description provided for @categoryWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get categoryWater;

  /// No description provided for @categoryElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get categoryElectricity;

  /// No description provided for @categorySanitation.
  ///
  /// In en, this message translates to:
  /// **'Sanitation'**
  String get categorySanitation;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @pollStatusLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get pollStatusLive;

  /// No description provided for @pollStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get pollStatusUpcoming;

  /// No description provided for @pollStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'CLOSED'**
  String get pollStatusClosed;

  /// No description provided for @pollVotedBadge.
  ///
  /// In en, this message translates to:
  /// **'VOTED'**
  String get pollVotedBadge;

  /// No description provided for @pollEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get pollEnded;

  /// No description provided for @pollEndsInDays.
  ///
  /// In en, this message translates to:
  /// **'Ends in {days}d'**
  String pollEndsInDays(int days);

  /// No description provided for @pollEndsInHours.
  ///
  /// In en, this message translates to:
  /// **'Ends in {hours}h'**
  String pollEndsInHours(int hours);

  /// No description provided for @pollEndsInMinutes.
  ///
  /// In en, this message translates to:
  /// **'Ends in {minutes}m'**
  String pollEndsInMinutes(int minutes);

  /// No description provided for @pollVotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} votes'**
  String pollVotesCount(int count);

  /// No description provided for @pollParticipating.
  ///
  /// In en, this message translates to:
  /// **'{count} participating'**
  String pollParticipating(int count);

  /// No description provided for @pollParticipatingWithCountdown.
  ///
  /// In en, this message translates to:
  /// **'{count} participating  •  {countdown}'**
  String pollParticipatingWithCountdown(int count, String countdown);

  /// No description provided for @pollOptionsWithCountdown.
  ///
  /// In en, this message translates to:
  /// **'{count} options · {countdown}'**
  String pollOptionsWithCountdown(int count, String countdown);

  /// No description provided for @profileFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Citizen'**
  String get profileFallbackName;

  /// No description provided for @profileSectionActivity.
  ///
  /// In en, this message translates to:
  /// **'My activity'**
  String get profileSectionActivity;

  /// No description provided for @profileReportsFiled.
  ///
  /// In en, this message translates to:
  /// **'reports filed'**
  String get profileReportsFiled;

  /// No description provided for @profileViewAllReports.
  ///
  /// In en, this message translates to:
  /// **'View all {count} reports'**
  String profileViewAllReports(int count);

  /// No description provided for @profileSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profileSectionPreferences;

  /// No description provided for @profileTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get profileTheme;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileSectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get profileSectionPrivacy;

  /// No description provided for @profileAnonymousVotingTitle.
  ///
  /// In en, this message translates to:
  /// **'Anonymous voting'**
  String get profileAnonymousVotingTitle;

  /// No description provided for @profileAnonymousVotingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your votes are always anonymous by design — results can never be traced back to you.'**
  String get profileAnonymousVotingSubtitle;

  /// No description provided for @profileLocationSharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Location sharing'**
  String get profileLocationSharingTitle;

  /// No description provided for @profileLocationSharingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only attached to a report when you choose to.'**
  String get profileLocationSharingSubtitle;

  /// No description provided for @profileSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileSectionAbout;

  /// No description provided for @profileAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{tagline}\nCDAC Final Project — Mobile Computing'**
  String profileAboutSubtitle(String tagline);

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Raise your voice for your city.\nSign in with your email.'**
  String get loginSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignIn;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get loginCreateAccount;

  /// No description provided for @loginHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get loginHaveAccount;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get registerNameLabel;

  /// No description provided for @registerSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerSignUp;

  /// No description provided for @validationEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get validationEnterEmail;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validationEmailInvalid;

  /// No description provided for @validationEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get validationEnterPassword;

  /// No description provided for @validationPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get validationPasswordLength;

  /// No description provided for @validationEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get validationEnterName;

  /// No description provided for @validationNameLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at most 100 characters'**
  String get validationNameLength;

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make your city better.'**
  String get homeSubtitle;

  /// No description provided for @homeActivePoll.
  ///
  /// In en, this message translates to:
  /// **'Active poll'**
  String get homeActivePoll;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickActions;

  /// No description provided for @homeQuickReport.
  ///
  /// In en, this message translates to:
  /// **'Report\nIssue'**
  String get homeQuickReport;

  /// No description provided for @homeQuickNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby\nIssues'**
  String get homeQuickNearby;

  /// No description provided for @homeQuickPolls.
  ///
  /// In en, this message translates to:
  /// **'Active\nPolls'**
  String get homeQuickPolls;

  /// No description provided for @homeQuickMyReports.
  ///
  /// In en, this message translates to:
  /// **'My\nReports'**
  String get homeQuickMyReports;

  /// No description provided for @homeNearbyIssues.
  ///
  /// In en, this message translates to:
  /// **'Nearby issues'**
  String get homeNearbyIssues;

  /// No description provided for @homeNoNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'No nearby reports'**
  String get homeNoNearbyTitle;

  /// No description provided for @homeNoNearbySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your area looks clean — or be the first to report.'**
  String get homeNoNearbySubtitle;

  /// No description provided for @homeYourReports.
  ///
  /// In en, this message translates to:
  /// **'Your reports'**
  String get homeYourReports;

  /// No description provided for @homeNoReports.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t reported anything yet.\nSpotted a problem? Tap + to report it.'**
  String get homeNoReports;

  /// No description provided for @homeCommunityImpact.
  ///
  /// In en, this message translates to:
  /// **'Community impact'**
  String get homeCommunityImpact;

  /// No description provided for @homeIssuesReported.
  ///
  /// In en, this message translates to:
  /// **'issues reported'**
  String get homeIssuesReported;

  /// No description provided for @homeResolved.
  ///
  /// In en, this message translates to:
  /// **'resolved'**
  String get homeResolved;

  /// No description provided for @homeResolutionRate.
  ///
  /// In en, this message translates to:
  /// **'resolution rate'**
  String get homeResolutionRate;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Issues Near You'**
  String get mapTitle;

  /// No description provided for @mapRecenter.
  ///
  /// In en, this message translates to:
  /// **'Center on my location'**
  String get mapRecenter;

  /// No description provided for @mapReportsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 report} other{{count} reports}}'**
  String mapReportsCount(int count);

  /// No description provided for @mapViewReport.
  ///
  /// In en, this message translates to:
  /// **'View Report'**
  String get mapViewReport;

  /// No description provided for @locationFallbackNotice.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable — showing a default area'**
  String get locationFallbackNotice;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @wizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get wizardTitle;

  /// No description provided for @wizardSubmitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get wizardSubmitReport;

  /// No description provided for @wizardCategoryQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is the problem?'**
  String get wizardCategoryQuestion;

  /// No description provided for @wizardCategoryRoads.
  ///
  /// In en, this message translates to:
  /// **'Roads'**
  String get wizardCategoryRoads;

  /// No description provided for @wizardCategoryStreetLights.
  ///
  /// In en, this message translates to:
  /// **'Street Lights'**
  String get wizardCategoryStreetLights;

  /// No description provided for @wizardCategoryWaste.
  ///
  /// In en, this message translates to:
  /// **'Waste'**
  String get wizardCategoryWaste;

  /// No description provided for @wizardCategoryWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get wizardCategoryWater;

  /// No description provided for @wizardCategoryTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get wizardCategoryTraffic;

  /// No description provided for @wizardCategoryPublicSpaces.
  ///
  /// In en, this message translates to:
  /// **'Public Spaces'**
  String get wizardCategoryPublicSpaces;

  /// No description provided for @wizardDescribeTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening?'**
  String get wizardDescribeTitle;

  /// No description provided for @wizardTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Short title, e.g. \"Large pothole near the bus stop\"'**
  String get wizardTitleHint;

  /// No description provided for @wizardDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue — what, where exactly, since when…'**
  String get wizardDescriptionHint;

  /// No description provided for @wizardAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get wizardAddPhotos;

  /// No description provided for @wizardPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Up to 3 photos — clear photos get reports fixed faster.'**
  String get wizardPhotosHint;

  /// No description provided for @wizardTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get wizardTakePhoto;

  /// No description provided for @wizardChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get wizardChooseGallery;

  /// No description provided for @wizardPickPhotoError.
  ///
  /// In en, this message translates to:
  /// **'Could not pick the photo — try again.'**
  String get wizardPickPhotoError;

  /// No description provided for @wizardUploadingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Uploading photos…'**
  String get wizardUploadingPhotos;

  /// No description provided for @wizardLocationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Where is the issue?'**
  String get wizardLocationQuestion;

  /// No description provided for @wizardNoLocationYet.
  ///
  /// In en, this message translates to:
  /// **'No location set yet'**
  String get wizardNoLocationYet;

  /// No description provided for @wizardUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get wizardUseMyLocation;

  /// No description provided for @wizardManualEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'No GPS? Enter coordinates manually'**
  String get wizardManualEntryTitle;

  /// No description provided for @wizardLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get wizardLatitude;

  /// No description provided for @wizardLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get wizardLongitude;

  /// No description provided for @wizardInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get wizardInvalid;

  /// No description provided for @wizardLocationNote.
  ///
  /// In en, this message translates to:
  /// **'Your location is used only for this report and helps the municipality find and fix the issue faster. You can copy coordinates from any maps app.'**
  String get wizardLocationNote;

  /// No description provided for @wizardLocationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location is blocked for this app.'**
  String get wizardLocationBlocked;

  /// No description provided for @wizardOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get wizardOpenSettings;

  /// No description provided for @wizardLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied — enter coordinates below.'**
  String get wizardLocationDenied;

  /// No description provided for @wizardLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Enter coordinates below.'**
  String get wizardLocationFailed;

  /// No description provided for @wizardSimilarTitle.
  ///
  /// In en, this message translates to:
  /// **'Similar reports nearby'**
  String get wizardSimilarTitle;

  /// No description provided for @wizardSimilarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reports within 300 m of your location, same category.'**
  String get wizardSimilarSubtitle;

  /// No description provided for @wizardCheckingNearby.
  ///
  /// In en, this message translates to:
  /// **'Checking nearby reports…'**
  String get wizardCheckingNearby;

  /// No description provided for @wizardNoSimilarTitle.
  ///
  /// In en, this message translates to:
  /// **'No similar reports'**
  String get wizardNoSimilarTitle;

  /// No description provided for @wizardNoSimilarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You seem to be the first to spot this here.'**
  String get wizardNoSimilarSubtitle;

  /// No description provided for @wizardSimilarFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{We found 1 similar report nearby. Supporting an existing report gets it fixed faster.} other{We found {count} similar reports nearby. Supporting an existing report gets it fixed faster.}}'**
  String wizardSimilarFound(int count);

  /// No description provided for @wizardSimilarDistance.
  ///
  /// In en, this message translates to:
  /// **'<300 m'**
  String get wizardSimilarDistance;

  /// No description provided for @wizardStillFileReport.
  ///
  /// In en, this message translates to:
  /// **'Still want to file your report? Submit below — more reports raise priority.'**
  String get wizardStillFileReport;

  /// No description provided for @wizardSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Report submitted!'**
  String get wizardSubmittedTitle;

  /// No description provided for @wizardSubmittedTrack.
  ///
  /// In en, this message translates to:
  /// **'Report #{id} · track it from Alerts or Profile'**
  String wizardSubmittedTrack(int id);

  /// No description provided for @wizardTrackReport.
  ///
  /// In en, this message translates to:
  /// **'Track your report'**
  String get wizardTrackReport;

  /// No description provided for @wizardBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get wizardBackHome;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get detailTitle;

  /// No description provided for @detailCitizen.
  ///
  /// In en, this message translates to:
  /// **'Citizen'**
  String get detailCitizen;

  /// No description provided for @detailUpvoteSupport.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person supports this} other{{count} people support this}}'**
  String detailUpvoteSupport(int count);

  /// No description provided for @detailOfficialUpdate.
  ///
  /// In en, this message translates to:
  /// **'OFFICIAL UPDATE'**
  String get detailOfficialUpdate;

  /// No description provided for @detailResolvedTitle.
  ///
  /// In en, this message translates to:
  /// **'🎉 Issue Resolved'**
  String get detailResolvedTitle;

  /// No description provided for @detailResolvedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your report helped bring attention to this issue.'**
  String get detailResolvedSubtitle;

  /// No description provided for @detailResolvedDates.
  ///
  /// In en, this message translates to:
  /// **'Reported {reported} · Resolved {resolved} · {duration}'**
  String detailResolvedDates(String reported, String resolved, String duration);

  /// No description provided for @detailSameDay.
  ///
  /// In en, this message translates to:
  /// **'same day'**
  String get detailSameDay;

  /// No description provided for @detailDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String detailDaysCount(int count);

  /// No description provided for @detailCitizensSupported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 citizen supported this report} other{{count} citizens supported this report}}'**
  String detailCitizensSupported(int count);

  /// No description provided for @detailProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get detailProgress;

  /// No description provided for @detailLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get detailLocation;

  /// No description provided for @detailComments.
  ///
  /// In en, this message translates to:
  /// **'Comments ({count})'**
  String detailComments(int count);

  /// No description provided for @detailNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet — start the conversation.'**
  String get detailNoComments;

  /// No description provided for @detailTimelineSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get detailTimelineSubmitted;

  /// No description provided for @detailTimelineResolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get detailTimelineResolution;

  /// No description provided for @detailTimelineReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get detailTimelineReview;

  /// No description provided for @detailCitizenNumber.
  ///
  /// In en, this message translates to:
  /// **'Citizen #{id}'**
  String detailCitizenNumber(String id);

  /// No description provided for @detailCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment…'**
  String get detailCommentHint;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @pollsTitle.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get pollsTitle;

  /// No description provided for @pollsSegmentActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get pollsSegmentActive;

  /// No description provided for @pollsSegmentUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get pollsSegmentUpcoming;

  /// No description provided for @pollsSegmentClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get pollsSegmentClosed;

  /// No description provided for @pollsPullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh.'**
  String get pollsPullToRefresh;

  /// No description provided for @pollsEmptyActive.
  ///
  /// In en, this message translates to:
  /// **'No active polls right now'**
  String get pollsEmptyActive;

  /// No description provided for @pollsEmptyUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming polls scheduled'**
  String get pollsEmptyUpcoming;

  /// No description provided for @pollsEmptyClosed.
  ///
  /// In en, this message translates to:
  /// **'No closed polls yet'**
  String get pollsEmptyClosed;

  /// No description provided for @pollDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get pollDetailTitle;

  /// No description provided for @pollOpenUntil.
  ///
  /// In en, this message translates to:
  /// **'open until'**
  String get pollOpenUntil;

  /// No description provided for @pollClosedLabel.
  ///
  /// In en, this message translates to:
  /// **'closed'**
  String get pollClosedLabel;

  /// No description provided for @pollAnonymousSuffix.
  ///
  /// In en, this message translates to:
  /// **' · anonymous'**
  String get pollAnonymousSuffix;

  /// No description provided for @pollCastVote.
  ///
  /// In en, this message translates to:
  /// **'Cast vote'**
  String get pollCastVote;

  /// No description provided for @pollAlreadyVoted.
  ///
  /// In en, this message translates to:
  /// **'You already voted in this poll — thanks for participating!'**
  String get pollAlreadyVoted;

  /// No description provided for @pollLiveResults.
  ///
  /// In en, this message translates to:
  /// **'Live results'**
  String get pollLiveResults;

  /// No description provided for @pollResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get pollResults;

  /// No description provided for @pollInsights.
  ///
  /// In en, this message translates to:
  /// **'Poll insights'**
  String get pollInsights;

  /// No description provided for @pollTopChoice.
  ///
  /// In en, this message translates to:
  /// **'Top choice'**
  String get pollTopChoice;

  /// No description provided for @pollParticipation.
  ///
  /// In en, this message translates to:
  /// **'Participation'**
  String get pollParticipation;

  /// No description provided for @pollEnds.
  ///
  /// In en, this message translates to:
  /// **'Poll ends'**
  String get pollEnds;

  /// No description provided for @pollCitizensCount.
  ///
  /// In en, this message translates to:
  /// **'{count} citizens'**
  String pollCitizensCount(int count);

  /// No description provided for @pollEndsInDaysHours.
  ///
  /// In en, this message translates to:
  /// **'Ends in {days}d {hours}h'**
  String pollEndsInDaysHours(int days, int hours);

  /// No description provided for @pollRefreshResults.
  ///
  /// In en, this message translates to:
  /// **'Refresh results'**
  String get pollRefreshResults;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// No description provided for @alertsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get alertsMarkAllRead;

  /// No description provided for @alertsNothingNew.
  ///
  /// In en, this message translates to:
  /// **'Nothing new'**
  String get alertsNothingNew;

  /// No description provided for @alertsNothingNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report an issue or vote in a poll to see updates here.'**
  String get alertsNothingNewSubtitle;

  /// No description provided for @alertsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get alertsToday;

  /// No description provided for @alertsYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get alertsYesterday;

  /// No description provided for @alertsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get alertsThisWeek;

  /// No description provided for @alertsEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get alertsEarlier;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutWhatYouCanDo.
  ///
  /// In en, this message translates to:
  /// **'What you can do'**
  String get aboutWhatYouCanDo;

  /// No description provided for @aboutBulletPolls.
  ///
  /// In en, this message translates to:
  /// **'Participate in public polls with live results'**
  String get aboutBulletPolls;

  /// No description provided for @aboutBulletReports.
  ///
  /// In en, this message translates to:
  /// **'Report local issues with photos and GPS location'**
  String get aboutBulletReports;

  /// No description provided for @aboutBulletSimilar.
  ///
  /// In en, this message translates to:
  /// **'Find and support similar reports nearby'**
  String get aboutBulletSimilar;

  /// No description provided for @aboutBulletResolution.
  ///
  /// In en, this message translates to:
  /// **'Track issue resolution with official updates'**
  String get aboutBulletResolution;

  /// No description provided for @aboutBulletNotifications.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications on status changes'**
  String get aboutBulletNotifications;

  /// No description provided for @aboutBuiltWith.
  ///
  /// In en, this message translates to:
  /// **'Built with'**
  String get aboutBuiltWith;

  /// No description provided for @aboutFooter.
  ///
  /// In en, this message translates to:
  /// **'CDAC Final Project — Mobile Computing\nMicroservices · Clean Architecture · One person, one vote'**
  String get aboutFooter;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
