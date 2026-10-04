import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:feedback_app/core/network/api_client.dart';
import 'package:feedback_app/core/network/token_store.dart';
import 'package:feedback_app/core/themes/app_theme.dart';
import 'package:feedback_app/features/alerts/data/datasources/notification_remote_data_source.dart';
import 'package:feedback_app/features/alerts/presentation/bloc/alerts_bloc.dart';
import 'package:feedback_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:feedback_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:feedback_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:feedback_app/features/feedback/data/datasources/feedback_remote_data_source.dart';
import 'package:feedback_app/features/feedback/data/repositories/feedback_repository_impl.dart';
import 'package:feedback_app/features/feedback/presentation/bloc/feedback_bloc.dart';
import 'package:feedback_app/features/home_shell.dart';
import 'package:feedback_app/features/polls/data/datasources/poll_remote_data_source.dart';
import 'package:feedback_app/features/polls/data/repositories/poll_repository_impl.dart';
import 'package:feedback_app/features/polls/presentation/bloc/polls_bloc.dart';
import 'package:feedback_app/features/profile/presentation/bloc/locale_cubit.dart';
import 'package:feedback_app/features/profile/presentation/bloc/theme_cubit.dart';
import 'package:feedback_app/l10n/gen/app_localizations.dart';

/// Backend calls fail fast so pages land in retry/empty states. The inbox
/// answers with an empty success: a failure would emit AlertsFailure and pop
/// a snackbar, whose auto-dismiss timer outlives the label assertions.
Future<http.Response> _offline(http.Request request) async {
  final ok = request.url.path.endsWith('/notifications/inbox');
  return http.Response(
    ok
        ? jsonEncode({'success': true, 'data': <Object>[]})
        : jsonEncode({'success': false, 'message': 'offline'}),
    ok ? 200 : 500,
    headers: {'content-type': 'application/json'},
  );
}

class _FakeTokenStore extends TokenStore {
  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<void> save({required String accessToken}) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('bottom-nav labels follow the language picked in Profile',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final api = ApiClient(client: MockClient(_offline));
    final tokenStore = _FakeTokenStore();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit(prefs)),
          BlocProvider(create: (_) => LocaleCubit(prefs)),
          BlocProvider(
            create: (_) => AuthBloc(
              repository: AuthRepositoryImpl(AuthRemoteDataSource(api), tokenStore),
            )..add(const AuthSessionRequested()),
          ),
          BlocProvider(
            create: (_) =>
                PollsBloc(repository: PollRepositoryImpl(PollRemoteDataSource(api))),
          ),
          BlocProvider(
            create: (_) => FeedbackBloc(
                repository: FeedbackRepositoryImpl(FeedbackRemoteDataSource(api))),
          ),
          BlocProvider(
            create: (_) =>
                AlertsBloc(remoteDataSource: NotificationRemoteDataSource(api)),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) => BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) => MaterialApp(
              theme: AppTheme.light(),
              themeMode: themeMode,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const HomeShell(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Finder navLabel(String text) => find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(text),
        );

    Future<void> switchLanguage(String current, String target) async {
      await tester.tap(find.text(current));
      await tester.pumpAndSettle();
      await tester.tap(find.text(target));
      await tester.pumpAndSettle();
    }

    // Default: English.
    for (final label in ['Home', 'Polls', 'Report', 'Alerts', 'Profile']) {
      expect(navLabel(label), findsOneWidget, reason: 'English label "$label"');
    }

    // Open Profile, pick हिन्दी.
    await tester.tap(navLabel('Profile'));
    await tester.pumpAndSettle();
    await switchLanguage('English', 'हिन्दी');

    for (final label in ['होम', 'पोल', 'रिपोर्ट', 'अलर्ट', 'प्रोफ़ाइल']) {
      expect(navLabel(label), findsOneWidget, reason: 'Hindi label "$label"');
    }
    expect(navLabel('Home'), findsNothing);
    expect(prefs.getString('app_locale'), 'hi');

    // Switch to मराठी.
    await switchLanguage('हिन्दी', 'मराठी');

    for (final label in ['होम', 'पोल', 'रिपोर्ट', 'अलर्ट', 'प्रोफाइल']) {
      expect(navLabel(label), findsOneWidget, reason: 'Marathi label "$label"');
    }
    expect(prefs.getString('app_locale'), 'mr');

    // And back to English.
    await switchLanguage('मराठी', 'English');

    for (final label in ['Home', 'Polls', 'Report', 'Alerts', 'Profile']) {
      expect(navLabel(label), findsOneWidget, reason: 'English label "$label"');
    }
    expect(prefs.getString('app_locale'), 'en');
  });
}
