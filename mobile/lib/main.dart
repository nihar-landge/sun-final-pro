import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:feedback_app/core/constants/app_constants.dart';
import 'package:feedback_app/core/network/api_client.dart';
import 'package:feedback_app/core/notifications/push_service.dart';
import 'package:feedback_app/core/network/token_store.dart';
import 'package:feedback_app/core/themes/app_theme.dart';
import 'package:feedback_app/features/alerts/data/datasources/notification_remote_data_source.dart';
import 'package:feedback_app/features/alerts/presentation/bloc/alerts_bloc.dart';
import 'package:feedback_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:feedback_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:feedback_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:feedback_app/features/auth/presentation/pages/login_page.dart';
import 'package:feedback_app/features/feedback/data/datasources/feedback_remote_data_source.dart';
import 'package:feedback_app/features/feedback/data/repositories/feedback_repository_impl.dart';
import 'package:feedback_app/features/feedback/presentation/bloc/feedback_bloc.dart';
import 'package:feedback_app/features/polls/data/datasources/poll_remote_data_source.dart';
import 'package:feedback_app/features/polls/data/repositories/poll_repository_impl.dart';
import 'package:feedback_app/features/polls/presentation/bloc/polls_bloc.dart';
import 'package:feedback_app/features/profile/presentation/bloc/theme_cubit.dart';

/// Manual dependency wiring (a get_it-based injection_container.dart replaces
/// this when the feature count justifies it).
TokenStore tokenStore = TokenStore();
ApiClient apiClient = ApiClient(tokenStore: tokenStore);

AuthBloc buildAuthBloc() => AuthBloc(
      repository: AuthRepositoryImpl(
        AuthRemoteDataSource(apiClient),
        tokenStore,
      ),
    );

PollsBloc buildPollsBloc() => PollsBloc(
      repository: PollRepositoryImpl(PollRemoteDataSource(apiClient)),
    );

FeedbackBloc buildFeedbackBloc() => FeedbackBloc(
      repository: FeedbackRepositoryImpl(FeedbackRemoteDataSource(apiClient)),
    );

AlertsBloc buildAlertsBloc() => AlertsBloc(
      remoteDataSource: NotificationRemoteDataSource(apiClient),
    );

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.preload(); // Firebase init (FCM push)
  final prefs = await SharedPreferences.getInstance();
  runApp(
    BlocProvider(
      create: (_) => ThemeCubit(prefs),
      child: const FeedbackApp(),
    ),
  );
}

class FeedbackApp extends StatelessWidget {
  const FeedbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => buildAuthBloc()..add(const AuthSessionRequested())),
        BlocProvider(create: (_) => buildPollsBloc()),
        BlocProvider(
            create: (_) => buildFeedbackBloc()..add(const MyReportsRequested())),
        BlocProvider(create: (_) => buildAlertsBloc()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp(
          title: AppConstants.appName,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          navigatorKey: PushService.navigatorKey,
          home: BlocListener<AuthBloc, AuthState>(
            listener: (context, authState) {
              if (authState is Authenticated) {
                PushService.register(tokenStore);
                PushService.handleInitialMessage();
              }
            },
            child: const LoginPage(),
          ),
        ),
      ),
    );
  }
}
