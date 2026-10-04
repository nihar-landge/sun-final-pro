// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTagline => 'आपकी आवाज़। आपका समुदाय। आपका प्रभाव।';

  @override
  String get commonTryAgain => 'फिर से प्रयास करें';

  @override
  String get commonSomethingWentWrong => 'कुछ गलत हो गया';

  @override
  String get commonView => 'देखें';

  @override
  String get navHome => 'होम';

  @override
  String get navPolls => 'पोल';

  @override
  String get navReport => 'रिपोर्ट';

  @override
  String get navAlerts => 'अलर्ट';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get statusOpen => 'खुला';

  @override
  String get statusInReview => 'समीक्षा में';

  @override
  String get statusResolved => 'हल हो गया';

  @override
  String get categoryRoads => 'सड़कें';

  @override
  String get categoryWater => 'पानी';

  @override
  String get categoryElectricity => 'बिजली';

  @override
  String get categorySanitation => 'स्वच्छता';

  @override
  String get categoryTransport => 'परिवहन';

  @override
  String get categoryOther => 'अन्य';

  @override
  String get pollStatusLive => 'लाइव';

  @override
  String get pollStatusUpcoming => 'आगामी';

  @override
  String get pollStatusClosed => 'बंद';

  @override
  String get pollVotedBadge => 'वोट दिया';

  @override
  String get pollEnded => 'समाप्त';

  @override
  String pollEndsInDays(int days) {
    return '$days दिन में समाप्त';
  }

  @override
  String pollEndsInHours(int hours) {
    return '$hours घंटे में समाप्त';
  }

  @override
  String pollEndsInMinutes(int minutes) {
    return '$minutes मिनट में समाप्त';
  }

  @override
  String pollVotesCount(int count) {
    return '$count वोट';
  }

  @override
  String pollParticipating(int count) {
    return '$count भाग ले रहे हैं';
  }

  @override
  String pollParticipatingWithCountdown(int count, String countdown) {
    return '$count भाग ले रहे हैं  •  $countdown';
  }

  @override
  String pollOptionsWithCountdown(int count, String countdown) {
    return '$count विकल्प · $countdown';
  }

  @override
  String get profileFallbackName => 'नागरिक';

  @override
  String get profileSectionActivity => 'मेरी गतिविधि';

  @override
  String get profileReportsFiled => 'रिपोर्ट दर्ज';

  @override
  String profileViewAllReports(int count) {
    return 'सभी $count रिपोर्ट देखें';
  }

  @override
  String get profileSectionPreferences => 'प्राथमिकताएँ';

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
      'आपके वोट हमेशा गुप्त रहते हैं — परिणाम कभी आपसे नहीं जोड़े जा सकते।';

  @override
  String get profileLocationSharingTitle => 'स्थान साझा करना';

  @override
  String get profileLocationSharingSubtitle =>
      'केवल तभी रिपोर्ट से जुड़ता है जब आप स्वयं चुनें।';

  @override
  String get profileSectionAbout => 'ऐप के बारे में';

  @override
  String profileAboutSubtitle(String tagline) {
    return '$tagline\nCDAC अंतिम परियोजना — मोबाइल कंप्यूटिंग';
  }

  @override
  String get profileSignOut => 'साइन आउट';

  @override
  String get loginSubtitle =>
      'अपने शहर के लिए आवाज़ उठाएँ।\nअपने ईमेल से साइन इन करें।';

  @override
  String get loginEmailLabel => 'ईमेल';

  @override
  String get loginPasswordLabel => 'पासवर्ड';

  @override
  String get loginSignIn => 'साइन इन करें';

  @override
  String get loginCreateAccount => 'नए हैं? खाता बनाएँ';

  @override
  String get loginHaveAccount => 'पहले से खाता है? साइन इन करें';

  @override
  String get registerTitle => 'अपना खाता बनाएँ';

  @override
  String get registerNameLabel => 'आपका नाम';

  @override
  String get registerSignUp => 'खाता बनाएँ';

  @override
  String get validationEnterEmail => 'अपना ईमेल दर्ज करें';

  @override
  String get validationEmailInvalid => 'मान्य ईमेल पता दर्ज करें';

  @override
  String get validationEnterPassword => 'अपना पासवर्ड दर्ज करें';

  @override
  String get validationPasswordLength =>
      'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए';

  @override
  String get validationEnterName => 'अपना नाम दर्ज करें';

  @override
  String get validationNameLength => 'नाम अधिकतम 100 अक्षरों का होना चाहिए';

  @override
  String get commonSeeAll => 'सभी देखें';

  @override
  String get homeGreetingMorning => 'सुप्रभात';

  @override
  String get homeGreetingAfternoon => 'शुभ दोपहर';

  @override
  String get homeGreetingEvening => 'शुभ संध्या';

  @override
  String get homeSubtitle => 'अपने शहर को बेहतर बनाएँ।';

  @override
  String get homeActivePoll => 'सक्रिय पोल';

  @override
  String get homeQuickActions => 'त्वरित कार्रवाई';

  @override
  String get homeQuickReport => 'रिपोर्ट\nदर्ज करें';

  @override
  String get homeQuickNearby => 'आसपास\nसमस्याएँ';

  @override
  String get homeQuickPolls => 'सक्रिय\nपोल';

  @override
  String get homeQuickMyReports => 'मेरी\nरिपोर्ट';

  @override
  String get homeNearbyIssues => 'आसपास की समस्याएँ';

  @override
  String get homeNoNearbyTitle => 'आसपास कोई रिपोर्ट नहीं';

  @override
  String get homeNoNearbySubtitle =>
      'आपका क्षेत्र साफ़ लगता है — या सबसे पहले रिपोर्ट करने वाले बनें।';

  @override
  String get homeYourReports => 'आपकी रिपोर्टें';

  @override
  String get homeNoReports =>
      'आपने अभी तक कोई रिपोर्ट दर्ज नहीं की।\nकोई समस्या दिखी? रिपोर्ट करने के लिए + दबाएँ।';

  @override
  String get homeCommunityImpact => 'समुदाय पर प्रभाव';

  @override
  String get homeIssuesReported => 'समस्याएँ दर्ज';

  @override
  String get homeResolved => 'हल हुईं';

  @override
  String get homeResolutionRate => 'समाधान दर';

  @override
  String get mapTitle => 'आपके आसपास की समस्याएँ';

  @override
  String get mapRecenter => 'मेरे स्थान पर केंद्रित करें';

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
  String get mapViewReport => 'रिपोर्ट देखें';

  @override
  String get locationFallbackNotice =>
      'स्थान उपलब्ध नहीं — डिफ़ॉल्ट क्षेत्र दिखाया जा रहा है';

  @override
  String get commonBack => 'वापस';

  @override
  String get commonContinue => 'जारी रखें';

  @override
  String get wizardTitle => 'समस्या की रिपोर्ट करें';

  @override
  String get wizardSubmitReport => 'रिपोर्ट सबमिट करें';

  @override
  String get wizardCategoryQuestion => 'समस्या क्या है?';

  @override
  String get wizardCategoryRoads => 'सड़कें';

  @override
  String get wizardCategoryStreetLights => 'स्ट्रीट लाइट';

  @override
  String get wizardCategoryWaste => 'कचरा';

  @override
  String get wizardCategoryWater => 'पानी';

  @override
  String get wizardCategoryTraffic => 'यातायात';

  @override
  String get wizardCategoryPublicSpaces => 'सार्वजनिक स्थान';

  @override
  String get wizardDescribeTitle => 'क्या हो रहा है?';

  @override
  String get wizardTitleHint =>
      'छोटा शीर्षक, जैसे \"बस स्टॉप के पास बड़ा गड्ढा\"';

  @override
  String get wizardDescriptionHint =>
      'समस्या का वर्णन करें — क्या, ठीक कहाँ, कब से…';

  @override
  String get wizardAddPhotos => 'फ़ोटो जोड़ें';

  @override
  String get wizardPhotosHint =>
      'अधिकतम 3 फ़ोटो — साफ़ फ़ोटो से रिपोर्ट जल्दी हल होती है।';

  @override
  String get wizardTakePhoto => 'फ़ोटो लें';

  @override
  String get wizardChooseGallery => 'गैलरी से चुनें';

  @override
  String get wizardPickPhotoError => 'फ़ोटो नहीं चुन पाए — फिर से प्रयास करें।';

  @override
  String get wizardUploadingPhotos => 'फ़ोटो अपलोड हो रही हैं…';

  @override
  String get wizardLocationQuestion => 'समस्या कहाँ है?';

  @override
  String get wizardNoLocationYet => 'अभी तक कोई स्थान सेट नहीं';

  @override
  String get wizardUseMyLocation => 'मेरा वर्तमान स्थान उपयोग करें';

  @override
  String get wizardManualEntryTitle => 'GPS नहीं? निर्देशांक स्वयं दर्ज करें';

  @override
  String get wizardLatitude => 'अक्षांश';

  @override
  String get wizardLongitude => 'देशांतर';

  @override
  String get wizardInvalid => 'अमान्य';

  @override
  String get wizardLocationNote =>
      'आपका स्थान केवल इस रिपोर्ट के लिए उपयोग होता है और नगरपालिका को समस्या जल्दी खोजने और ठीक करने में मदद करता है। आप किसी भी मैप ऐप से निर्देशांक कॉपी कर सकते हैं।';

  @override
  String get wizardLocationBlocked => 'इस ऐप के लिए स्थान अवरुद्ध है।';

  @override
  String get wizardOpenSettings => 'सेटिंग्स खोलें';

  @override
  String get wizardLocationDenied =>
      'स्थान की अनुमति नहीं दी गई — नीचे निर्देशांक दर्ज करें।';

  @override
  String get wizardLocationFailed =>
      'आपका स्थान प्राप्त नहीं हो सका। नीचे निर्देशांक दर्ज करें।';

  @override
  String get wizardSimilarTitle => 'आसपास समान रिपोर्ट';

  @override
  String get wizardSimilarSubtitle =>
      'आपके स्थान के 300 मीटर के भीतर, समान श्रेणी की रिपोर्ट।';

  @override
  String get wizardCheckingNearby => 'आसपास की रिपोर्ट जाँच रहे हैं…';

  @override
  String get wizardNoSimilarTitle => 'कोई समान रिपोर्ट नहीं';

  @override
  String get wizardNoSimilarSubtitle =>
      'लगता है आपने यहाँ यह सबसे पहले देखा है।';

  @override
  String wizardSimilarFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'हमें आसपास $count समान रिपोर्ट मिलीं। मौजूदा रिपोर्ट का समर्थन करने से वह जल्दी हल होती है।',
      one:
          'हमें आसपास 1 समान रिपोर्ट मिली। मौजूदा रिपोर्ट का समर्थन करने से वह जल्दी हल होती है।',
    );
    return '$_temp0';
  }

  @override
  String get wizardSimilarDistance => '<300 मी';

  @override
  String get wizardStillFileReport =>
      'फिर भी अपनी रिपोर्ट दर्ज करना चाहते हैं? नीचे सबमिट करें — अधिक रिपोर्टों से प्राथमिकता बढ़ती है।';

  @override
  String get wizardSubmittedTitle => 'रिपोर्ट सबमिट हो गई!';

  @override
  String wizardSubmittedTrack(int id) {
    return 'रिपोर्ट #$id · अलर्ट या प्रोफ़ाइल से ट्रैक करें';
  }

  @override
  String get wizardTrackReport => 'अपनी रिपोर्ट ट्रैक करें';

  @override
  String get wizardBackHome => 'होम पर वापस जाएँ';

  @override
  String get detailTitle => 'रिपोर्ट';

  @override
  String get detailCitizen => 'नागरिक';

  @override
  String detailUpvoteSupport(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count लोग इसका समर्थन करते हैं',
      one: '1 व्यक्ति इसका समर्थन करता है',
    );
    return '$_temp0';
  }

  @override
  String get detailOfficialUpdate => 'आधिकारिक अपडेट';

  @override
  String get detailResolvedTitle => '🎉 समस्या हल हो गई';

  @override
  String get detailResolvedSubtitle =>
      'आपकी रिपोर्ट ने इस समस्या की ओर ध्यान आकर्षित किया।';

  @override
  String detailResolvedDates(
    String reported,
    String resolved,
    String duration,
  ) {
    return 'दर्ज $reported · हल $resolved · $duration';
  }

  @override
  String get detailSameDay => 'उसी दिन';

  @override
  String detailDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन',
      one: '1 दिन',
    );
    return '$_temp0';
  }

  @override
  String detailCitizensSupported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नागरिकों ने इस रिपोर्ट का समर्थन किया',
      one: '1 नागरिक ने इस रिपोर्ट का समर्थन किया',
    );
    return '$_temp0';
  }

  @override
  String get detailProgress => 'प्रगति';

  @override
  String get detailLocation => 'स्थान';

  @override
  String detailComments(int count) {
    return 'टिप्पणियाँ ($count)';
  }

  @override
  String get detailNoComments => 'अभी कोई टिप्पणी नहीं — बातचीत शुरू करें।';

  @override
  String get detailTimelineSubmitted => 'रिपोर्ट दर्ज हुई';

  @override
  String get detailTimelineResolution => 'समाधान';

  @override
  String get detailTimelineReview => 'समीक्षा';

  @override
  String detailCitizenNumber(String id) {
    return 'नागरिक #$id';
  }

  @override
  String get detailCommentHint => 'टिप्पणी लिखें…';

  @override
  String get commonRefresh => 'रीफ़्रेश करें';

  @override
  String get pollsTitle => 'पोल';

  @override
  String get pollsSegmentActive => 'सक्रिय';

  @override
  String get pollsSegmentUpcoming => 'आगामी';

  @override
  String get pollsSegmentClosed => 'बंद';

  @override
  String get pollsPullToRefresh => 'रीफ़्रेश करने के लिए नीचे खींचें।';

  @override
  String get pollsEmptyActive => 'अभी कोई सक्रिय पोल नहीं';

  @override
  String get pollsEmptyUpcoming => 'कोई आगामी पोल निर्धारित नहीं';

  @override
  String get pollsEmptyClosed => 'अभी कोई बंद पोल नहीं';

  @override
  String get pollDetailTitle => 'पोल';

  @override
  String get pollOpenUntil => 'खुला रहेगा:';

  @override
  String get pollClosedLabel => 'बंद हुआ:';

  @override
  String get pollAnonymousSuffix => ' · गुप्त';

  @override
  String get pollCastVote => 'वोट दें';

  @override
  String get pollAlreadyVoted =>
      'आप इस पोल में वोट दे चुके हैं — भाग लेने के लिए धन्यवाद!';

  @override
  String get pollLiveResults => 'लाइव परिणाम';

  @override
  String get pollResults => 'परिणाम';

  @override
  String get pollInsights => 'पोल की जानकारी';

  @override
  String get pollTopChoice => 'शीर्ष पसंद';

  @override
  String get pollParticipation => 'भागीदारी';

  @override
  String get pollEnds => 'पोल समाप्ति';

  @override
  String pollCitizensCount(int count) {
    return '$count नागरिक';
  }

  @override
  String pollEndsInDaysHours(int days, int hours) {
    return '$days दिन $hours घंटे में समाप्त';
  }

  @override
  String get pollRefreshResults => 'परिणाम रीफ़्रेश करें';

  @override
  String get alertsTitle => 'अलर्ट';

  @override
  String get alertsMarkAllRead => 'सभी पढ़ा हुआ चिह्नित करें';

  @override
  String get alertsNothingNew => 'कुछ नया नहीं';

  @override
  String get alertsNothingNewSubtitle =>
      'यहाँ अपडेट देखने के लिए समस्या रिपोर्ट करें या पोल में वोट करें।';

  @override
  String get alertsToday => 'आज';

  @override
  String get alertsYesterday => 'कल';

  @override
  String get alertsThisWeek => 'इस सप्ताह';

  @override
  String get alertsEarlier => 'पहले';

  @override
  String get aboutTitle => 'ऐप के बारे में';

  @override
  String get aboutWhatYouCanDo => 'आप क्या कर सकते हैं';

  @override
  String get aboutBulletPolls =>
      'लाइव परिणामों के साथ सार्वजनिक पोल में भाग लें';

  @override
  String get aboutBulletReports =>
      'फ़ोटो और GPS स्थान के साथ स्थानीय समस्याएँ रिपोर्ट करें';

  @override
  String get aboutBulletSimilar => 'आसपास की समान रिपोर्ट खोजें और समर्थन करें';

  @override
  String get aboutBulletResolution =>
      'आधिकारिक अपडेट के साथ समस्या समाधान ट्रैक करें';

  @override
  String get aboutBulletNotifications => 'स्थिति बदलने पर पुश सूचनाएँ पाएँ';

  @override
  String get aboutBuiltWith => 'प्रौद्योगिकी';

  @override
  String get aboutFooter =>
      'CDAC अंतिम परियोजना — मोबाइल कंप्यूटिंग\nमाइक्रोसर्विसेज़ · क्लीन आर्किटेक्चर · एक व्यक्ति, एक वोट';
}
