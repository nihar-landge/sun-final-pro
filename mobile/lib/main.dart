import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/constants/app_constants.dart';
import 'package:feedback_app/core/network/api_client.dart';
import 'package:feedback_app/core/network/token_store.dart';
import 'package:feedback_app/core/themes/app_theme.dart';
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

/// Manual dependency wiring (a get_it-based injection_container.dart replaces
/// this once more features land).
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FeedbackApp());
}

class FeedbackApp extends StatelessWidget {
  const FeedbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => buildAuthBloc()..add(const AuthSessionRequested())),
        BlocProvider(create: (_) => buildPollsBloc()..add(const PollsRequested())),
        BlocProvider(create: (_) => buildFeedbackBloc()..add(const FeedbackListRequested())),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const LoginPage(),
      ),
    );
  }
}
