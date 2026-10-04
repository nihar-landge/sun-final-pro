// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTagline => 'तुमची आवाज. तुमचा समुदाय. तुमचा प्रभाव.';

  @override
  String get commonTryAgain => 'पुन्हा प्रयत्न करा';

  @override
  String get commonSomethingWentWrong => 'काहीतरी चुकले';

  @override
  String get commonView => 'पहा';

  @override
  String get navHome => 'होम';

  @override
  String get navPolls => 'पोल';

  @override
  String get navReport => 'रिपोर्ट';

  @override
  String get navAlerts => 'अलर्ट';

  @override
  String get navProfile => 'प्रोफाइल';

  @override
  String get statusOpen => 'खुले';

  @override
  String get statusInReview => 'पुनरावलोकनात';

  @override
  String get statusResolved => 'सोडवले';

  @override
  String get categoryRoads => 'रस्ते';

  @override
  String get categoryWater => 'पाणी';

  @override
  String get categoryElectricity => 'वीज';

  @override
  String get categorySanitation => 'स्वच्छता';

  @override
  String get categoryTransport => 'परिवहन';

  @override
  String get categoryOther => 'इतर';

  @override
  String get pollStatusLive => 'लाइव्ह';

  @override
  String get pollStatusUpcoming => 'आगामी';

  @override
  String get pollStatusClosed => 'बंद';

  @override
  String get pollVotedBadge => 'मत दिले';

  @override
  String get pollEnded => 'संपले';

  @override
  String pollEndsInDays(int days) {
    return '$days दिवसांत संपेल';
  }

  @override
  String pollEndsInHours(int hours) {
    return '$hours तासांत संपेल';
  }

  @override
  String pollEndsInMinutes(int minutes) {
    return '$minutes मिनिटांत संपेल';
  }

  @override
  String pollVotesCount(int count) {
    return '$count मते';
  }

  @override
  String pollParticipating(int count) {
    return '$count सहभागी';
  }

  @override
  String pollParticipatingWithCountdown(int count, String countdown) {
    return '$count सहभागी  •  $countdown';
  }

  @override
  String pollOptionsWithCountdown(int count, String countdown) {
    return '$count पर्याय · $countdown';
  }

  @override
  String get profileFallbackName => 'नागरिक';

  @override
  String get profileSectionActivity => 'माझी गतिविधी';

  @override
  String get profileReportsFiled => 'रिपोर्ट दाखल';

  @override
  String profileViewAllReports(int count) {
    return 'सर्व $count रिपोर्ट पहा';
  }

  @override
  String get profileSectionPreferences => 'प्राधान्ये';

  @override
  String get profileTheme => 'थीम';

  @override
  String get profileLanguage => 'भाषा';

  @override
  String get profileSectionPrivacy => 'गोपनीयता';

  @override
  String get profileAnonymousVotingTitle => 'गुप्त मतदान';

  @override
  String get profileAnonymousVotingSubtitle =>
      'तुमची मते नेहमीच गुप्त असतात — निकाल तुमच्याशी कधीही जोडले जाऊ शकत नाहीत.';

  @override
  String get profileLocationSharingTitle => 'स्थान शेअरिंग';

  @override
  String get profileLocationSharingSubtitle =>
      'तुम्ही निवडल्यावरच रिपोर्टला जोडले जाते.';

  @override
  String get profileSectionAbout => 'ॲपबद्दल';

  @override
  String profileAboutSubtitle(String tagline) {
    return '$tagline\nCDAC अंतिम प्रकल्प — मोबाइल कंप्युटिंग';
  }

  @override
  String get profileSignOut => 'साइन आउट';

  @override
  String get loginSubtitle =>
      'तुमच्या शहरासाठी आवाज उठवा.\nतुमच्या ईमेलने साइन इन करा.';

  @override
  String get loginEmailLabel => 'ईमेल';

  @override
  String get loginPasswordLabel => 'पासवर्ड';

  @override
  String get loginSignIn => 'साइन इन करा';

  @override
  String get loginCreateAccount => 'नवीन आहात? खाते तयार करा';

  @override
  String get loginHaveAccount => 'आधीच खाते आहे? साइन इन करा';

  @override
  String get registerTitle => 'तुमचे खाते तयार करा';

  @override
  String get registerNameLabel => 'तुमचे नाव';

  @override
  String get registerSignUp => 'खाते तयार करा';

  @override
  String get validationEnterEmail => 'तुमचा ईमेल टाका';

  @override
  String get validationEmailInvalid => 'वैध ईमेल पत्ता टाका';

  @override
  String get validationEnterPassword => 'तुमचा पासवर्ड टाका';

  @override
  String get validationPasswordLength => 'पासवर्ड किमान 8 अक्षरांचा असावा';

  @override
  String get validationEnterName => 'तुमचे नाव टाका';

  @override
  String get validationNameLength => 'नाव जास्तीत जास्त 100 अक्षरी असावे';

  @override
  String get commonSeeAll => 'सर्व पहा';

  @override
  String get homeGreetingMorning => 'शुभ सकाळ';

  @override
  String get homeGreetingAfternoon => 'शुभ दुपार';

  @override
  String get homeGreetingEvening => 'शुभ संध्याकाळ';

  @override
  String get homeSubtitle => 'तुमचे शहर अधिक चांगले करा.';

  @override
  String get homeActivePoll => 'सक्रिय पोल';

  @override
  String get homeQuickActions => 'त्वरित कृती';

  @override
  String get homeQuickReport => 'रिपोर्ट\nनोंदवा';

  @override
  String get homeQuickNearby => 'जवळपास\nसमस्या';

  @override
  String get homeQuickPolls => 'सक्रिय\nपोल';

  @override
  String get homeQuickMyReports => 'माझी\nरिपोर्ट';

  @override
  String get homeNearbyIssues => 'जवळपासच्या समस्या';

  @override
  String get homeNoNearbyTitle => 'जवळपास एकही रिपोर्ट नाही';

  @override
  String get homeNoNearbySubtitle =>
      'तुमचा परिसर स्वच्छ दिसतो — किंवा सर्वात आधी रिपोर्ट करा.';

  @override
  String get homeYourReports => 'तुमची रिपोर्ट';

  @override
  String get homeNoReports =>
      'तुम्ही अजून एकही रिपोर्ट नोंदवली नाही.\nसमस्या दिसली? नोंदवण्यासाठी + टॅप करा.';

  @override
  String get homeCommunityImpact => 'समुदायावर प्रभाव';

  @override
  String get homeIssuesReported => 'समस्या नोंदवल्या';

  @override
  String get homeResolved => 'सोडवल्या';

  @override
  String get homeResolutionRate => 'निराकरण दर';

  @override
  String get mapTitle => 'तुमच्या जवळील समस्या';

  @override
  String get mapRecenter => 'माझ्या स्थानावर केंद्रित करा';

  @override
  String mapReportsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिपोर्ट',
      one: '1 रिपोर्ट',
    );
    return '$_temp0';
  }

  @override
  String get mapViewReport => 'रिपोर्ट पहा';

  @override
  String get locationFallbackNotice =>
      'स्थान उपलब्ध नाही — डीफॉल्ट भाग दाखवत आहे';

  @override
  String get commonBack => 'मागे';

  @override
  String get commonContinue => 'पुढे';

  @override
  String get wizardTitle => 'समस्या नोंदवा';

  @override
  String get wizardSubmitReport => 'रिपोर्ट सबमिट करा';

  @override
  String get wizardCategoryQuestion => 'समस्या काय आहे?';

  @override
  String get wizardCategoryRoads => 'रस्ते';

  @override
  String get wizardCategoryStreetLights => 'स्ट्रीट लाइट';

  @override
  String get wizardCategoryWaste => 'कचरा';

  @override
  String get wizardCategoryWater => 'पाणी';

  @override
  String get wizardCategoryTraffic => 'वाहतूक';

  @override
  String get wizardCategoryPublicSpaces => 'सार्वजनिक जागा';

  @override
  String get wizardDescribeTitle => 'काय घडत आहे?';

  @override
  String get wizardTitleHint =>
      'थोडक्यात शीर्षक, उदा. \"बस थांब्याजवळ मोठा खड्डा\"';

  @override
  String get wizardDescriptionHint =>
      'समस्येचे वर्णन करा — काय, नेमके कुठे, कधीपासून…';

  @override
  String get wizardAddPhotos => 'फोटो जोडा';

  @override
  String get wizardPhotosHint =>
      'जास्तीत जास्त 3 फोटो — स्पष्ट फोटोंमुळे रिपोर्ट लवकर सोडवली जाते.';

  @override
  String get wizardTakePhoto => 'फोटो घ्या';

  @override
  String get wizardChooseGallery => 'गॅलरीमधून निवडा';

  @override
  String get wizardPickPhotoError =>
      'फोटो निवडता आला नाही — पुन्हा प्रयत्न करा.';

  @override
  String get wizardUploadingPhotos => 'फोटो अपलोड होत आहेत…';

  @override
  String get wizardLocationQuestion => 'समस्या कुठे आहे?';

  @override
  String get wizardNoLocationYet => 'अजून स्थान सेट केलेले नाही';

  @override
  String get wizardUseMyLocation => 'माझे सध्याचे स्थान वापरा';

  @override
  String get wizardManualEntryTitle => 'GPS नाही? निर्देशांक स्वतः टाका';

  @override
  String get wizardLatitude => 'अक्षांश';

  @override
  String get wizardLongitude => 'रेखांश';

  @override
  String get wizardInvalid => 'अवैध';

  @override
  String get wizardLocationNote =>
      'तुमचे स्थान फक्त या रिपोर्टसाठी वापरले जाते आणि महानगरपालिकेला समस्या लवकर शोधून सोडवण्यास मदत करते. तुम्ही कोणत्याही मॅप ॲपमधून निर्देशांक कॉपी करू शकता.';

  @override
  String get wizardLocationBlocked => 'या ॲपसाठी स्थान ब्लॉक केलेले आहे.';

  @override
  String get wizardOpenSettings => 'सेटिंग्ज उघडा';

  @override
  String get wizardLocationDenied =>
      'स्थान परवानगी नाकारली — खाली निर्देशांक टाका.';

  @override
  String get wizardLocationFailed =>
      'तुमचे स्थान मिळू शकले नाही. खाली निर्देशांक टाका.';

  @override
  String get wizardSimilarTitle => 'जवळपासच्या समान रिपोर्ट';

  @override
  String get wizardSimilarSubtitle =>
      'तुमच्या स्थानाच्या 300 मीटर आत, समान प्रकारच्या रिपोर्ट.';

  @override
  String get wizardCheckingNearby => 'जवळपासच्या रिपोर्ट तपासत आहे…';

  @override
  String get wizardNoSimilarTitle => 'एकही समान रिपोर्ट नाही';

  @override
  String get wizardNoSimilarSubtitle => 'हे तुम्हीच सर्वात आधी पाहिलेले दिसते.';

  @override
  String wizardSimilarFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'जवळपास $count समान रिपोर्ट आढळल्या. आधीच्याच रिपोर्टला पाठिंबा दिल्यास ती लवकर सोडवली जाते.',
      one:
          'जवळपास 1 समान रिपोर्ट आढळली. आधीच्याच रिपोर्टला पाठिंबा दिल्यास ती लवकर सोडवली जाते.',
    );
    return '$_temp0';
  }

  @override
  String get wizardSimilarDistance => '<300 मी';

  @override
  String get wizardStillFileReport =>
      'तरीही तुमची रिपोर्ट नोंदवायची आहे? खाली सबमिट करा — जास्त रिपोर्ट्समुळे प्राधान्य वाढते.';

  @override
  String get wizardSubmittedTitle => 'रिपोर्ट सबमिट झाली!';

  @override
  String wizardSubmittedTrack(int id) {
    return 'रिपोर्ट #$id · अलर्ट किंवा प्रोफाइलमधून ट्रॅक करा';
  }

  @override
  String get wizardTrackReport => 'तुमची रिपोर्ट ट्रॅक करा';

  @override
  String get wizardBackHome => 'मुख्यपृष्ठावर परत';

  @override
  String get detailTitle => 'रिपोर्ट';

  @override
  String get detailCitizen => 'नागरिक';

  @override
  String detailUpvoteSupport(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count लोकांनी या रिपोर्टला पाठिंबा दिला',
      one: '1 व्यक्तीने या रिपोर्टला पाठिंबा दिला',
    );
    return '$_temp0';
  }

  @override
  String get detailOfficialUpdate => 'अधिकृत अपडेट';

  @override
  String get detailResolvedTitle => '🎉 समस्या सोडवली';

  @override
  String get detailResolvedSubtitle =>
      'तुमच्या रिपोर्टमुळे या समस्येकडे लक्ष वेधले गेले.';

  @override
  String detailResolvedDates(
    String reported,
    String resolved,
    String duration,
  ) {
    return 'नोंद $reported · निराकरण $resolved · $duration';
  }

  @override
  String get detailSameDay => 'त्याच दिवशी';

  @override
  String detailDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिवस',
      one: '1 दिवस',
    );
    return '$_temp0';
  }

  @override
  String detailCitizensSupported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नागरिकांनी या रिपोर्टला पाठिंबा दिला',
      one: '1 नागरिकाने या रिपोर्टला पाठिंबा दिला',
    );
    return '$_temp0';
  }

  @override
  String get detailProgress => 'प्रगती';

  @override
  String get detailLocation => 'स्थान';

  @override
  String detailComments(int count) {
    return 'टिप्पण्या ($count)';
  }

  @override
  String get detailNoComments => 'अजून टिप्पण्या नाहीत — संवाद सुरू करा.';

  @override
  String get detailTimelineSubmitted => 'रिपोर्ट नोंदवली';

  @override
  String get detailTimelineResolution => 'निराकरण';

  @override
  String get detailTimelineReview => 'पुनरावलोकन';

  @override
  String detailCitizenNumber(String id) {
    return 'नागरिक #$id';
  }

  @override
  String get detailCommentHint => 'टिप्पणी लिहा…';

  @override
  String get commonRefresh => 'रिफ्रेश करा';

  @override
  String get pollsTitle => 'पोल';

  @override
  String get pollsSegmentActive => 'सक्रिय';

  @override
  String get pollsSegmentUpcoming => 'आगामी';

  @override
  String get pollsSegmentClosed => 'बंद';

  @override
  String get pollsPullToRefresh => 'रिफ्रेश करण्यासाठी खाली ओढा.';

  @override
  String get pollsEmptyActive => 'सध्या कोणतेही सक्रिय पोल नाहीत';

  @override
  String get pollsEmptyUpcoming => 'कोणतेही आगामी पोल नियोजित नाहीत';

  @override
  String get pollsEmptyClosed => 'अजून कोणतेही बंद पोल नाहीत';

  @override
  String get pollDetailTitle => 'पोल';

  @override
  String get pollOpenUntil => 'उघडे राहील:';

  @override
  String get pollClosedLabel => 'बंद झाले:';

  @override
  String get pollAnonymousSuffix => ' · गुप्त';

  @override
  String get pollCastVote => 'मत द्या';

  @override
  String get pollAlreadyVoted =>
      'तुम्ही या पोलमध्ये आधीच मत दिले आहे — सहभागासाठी धन्यवाद!';

  @override
  String get pollLiveResults => 'थेट निकाल';

  @override
  String get pollResults => 'निकाल';

  @override
  String get pollInsights => 'पोल माहिती';

  @override
  String get pollTopChoice => 'सर्वाधिक पसंती';

  @override
  String get pollParticipation => 'सहभाग';

  @override
  String get pollEnds => 'पोल संपेल';

  @override
  String pollCitizensCount(int count) {
    return '$count नागरिक';
  }

  @override
  String pollEndsInDaysHours(int days, int hours) {
    return '$days दिवस $hours तासांत संपेल';
  }

  @override
  String get pollRefreshResults => 'निकाल रिफ्रेश करा';

  @override
  String get alertsTitle => 'अलर्ट';

  @override
  String get alertsMarkAllRead => 'सर्व वाचलेले म्हणून चिन्हांकित करा';

  @override
  String get alertsNothingNew => 'काहीही नवीन नाही';

  @override
  String get alertsNothingNewSubtitle =>
      'येथे अपडेट पाहण्यासाठी समस्या नोंदवा किंवा पोलमध्ये मत द्या.';

  @override
  String get alertsToday => 'आज';

  @override
  String get alertsYesterday => 'काल';

  @override
  String get alertsThisWeek => 'या आठवड्यात';

  @override
  String get alertsEarlier => 'आधी';

  @override
  String get aboutTitle => 'ॲपबद्दल';

  @override
  String get aboutWhatYouCanDo => 'तुम्ही काय करू शकता';

  @override
  String get aboutBulletPolls => 'थेट निकालांसह सार्वजनिक पोलमध्ये सहभागी व्हा';

  @override
  String get aboutBulletReports =>
      'फोटो आणि GPS स्थानासह स्थानिक समस्या नोंदवा';

  @override
  String get aboutBulletSimilar =>
      'जवळपासचे समान रिपोर्ट शोधा आणि पाठिंबा द्या';

  @override
  String get aboutBulletResolution =>
      'अधिकृत अपडेट्ससह समस्या निराकरण ट्रॅक करा';

  @override
  String get aboutBulletNotifications => 'स्थिती बदलल्यावर पुश सूचना मिळवा';

  @override
  String get aboutBuiltWith => 'तंत्रज्ञान';

  @override
  String get aboutFooter =>
      'CDAC अंतिम प्रकल्प — मोबाइल कंप्युटिंग\nमायक्रोसर्व्हिसेस · क्लीन आर्किटेक्चर · एक व्यक्ती, एक मत';
}
