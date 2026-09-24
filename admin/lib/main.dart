import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_admin/core/api_client.dart';
import 'package:feedback_admin/core/theme.dart';
import 'package:feedback_admin/features/audit/audit_bloc.dart';
import 'package:feedback_admin/features/reports/reports_bloc.dart';
import 'package:feedback_admin/features/shell/admin_shell.dart';
import 'package:feedback_admin/features/analytics/admin_analytics_bloc.dart';
import 'package:feedback_admin/features/auth/admin_auth_bloc.dart';
import 'package:feedback_admin/features/feedback/admin_feedback_bloc.dart';
import 'package:feedback_admin/features/polls/admin_polls_bloc.dart';
import 'package:feedback_admin/features/users/admin_users_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FeedbackAdminApp());
}

class FeedbackAdminApp extends StatelessWidget {
  const FeedbackAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = AdminApiClient();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AdminAuthBloc(apiClient: apiClient)),
        BlocProvider(create: (_) => AdminPollsBloc(apiClient: apiClient)),
        BlocProvider(create: (_) => AdminFeedbackBloc(apiClient: apiClient)),
        BlocProvider(create: (_) => AdminAnalyticsBloc(apiClient: apiClient)),
        BlocProvider(create: (_) => AdminUsersBloc(apiClient: apiClient)),
        BlocProvider(create: (_) => ReportsBloc(apiClient: apiClient)),
        BlocProvider(create: (_) => AuditBloc(apiClient: apiClient)),
      ],
      child: MaterialApp(
        title: 'CivicPulse — Admin Console',
        theme: AdminTheme.light(),
        home: const AdminGate(),
      ),
    );
  }
}

/// Starts at the login screen; after authentication shows the dashboard.
class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminAuthBloc, AdminAuthState>(
      listener: (context, state) {
        if (state is AdminAuthFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is AdminAuthenticated) {
          context.read<AdminUsersBloc>().setCurrentAdminId(state.userId);
          context.read<AdminUsersBloc>().add(const AdminUsersSearched());
        }
      },
      builder: (context, state) {
        if (state is AdminAuthenticated) return const AdminDashboardPage();
        return const AdminLoginPage();
      },
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _phoneController = TextEditingController(text: '9999999999');
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: BlocBuilder<AdminAuthBloc, AdminAuthState>(
          builder: (context, state) {
            if (state is AdminAuthLoading) {
              return const CircularProgressIndicator();
            }
            if (state is AdminAccessDenied) {
              return const _DeniedCard();
            }
            final otpSent = state is AdminOtpSent;
            return _LoginCard(
              phoneController: _phoneController,
              otpController: _otpController,
              otpSent: otpSent,
              sentPhone: otpSent ? state.phone : null,
            );
          },
        ),
      ),
    );
  }
}

class _DeniedCard extends StatelessWidget {
  const _DeniedCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('This account does not have admin access.'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  context.read<AdminAuthBloc>().add(AdminLogoutRequested()),
              child: const Text('Try another account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final bool otpSent;
  final String? sentPhone;

  const _LoginCard({
    required this.phoneController,
    required this.otpController,
    required this.otpSent,
    this.sentPhone,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Admin Sign in',
                  style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('Public Feedback & Polling System',
                  style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              if (!otpSent) ...[
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Admin phone number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context
                      .read<AdminAuthBloc>()
                      .add(AdminOtpSendRequested(phoneController.text.trim())),
                  child: const Text('Send OTP'),
                ),
              ] else ...[
                Text('Code sent to $sentPhone', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextField(
                  controller: otpController,
                  decoration: const InputDecoration(labelText: '6-digit OTP'),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.read<AdminAuthBloc>().add(
                        AdminOtpVerifyRequested(
                          phone: sentPhone!,
                          code: otpController.text.trim(),
                        ),
                      ),
                  child: const Text('Sign in'),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Dev: OTP is printed in the auth-service log (dev echo)',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The municipal operations console (sidebar shell).
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell();
  }
}
