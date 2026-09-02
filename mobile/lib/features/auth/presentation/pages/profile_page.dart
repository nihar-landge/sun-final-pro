import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:feedback_app/features/auth/presentation/pages/login_page.dart';

/// Profile tab: shows the signed-in user and a sign-out action.
/// (Sign-out currently returns to the login screen; token revocation and
/// persisted sessions arrive with weeks 3-4.)
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    final name = state is Authenticated ? state.user.name : 'Citizen';
    final phone = state is Authenticated ? state.user.phone : '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
            ),
            const SizedBox(height: 12),
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            if (phone.isNotEmpty) Text(phone),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              onPressed: () {
                // Revokes the refresh token server-side and clears secure storage.
                context.read<AuthBloc>().add(LogoutRequested());
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
