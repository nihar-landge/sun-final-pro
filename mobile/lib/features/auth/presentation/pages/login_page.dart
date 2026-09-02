import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/constants/app_constants.dart';
import 'package:feedback_app/core/utils/validators.dart';
import 'package:feedback_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:feedback_app/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:feedback_app/features/home_shell.dart';

/// Phone number entry — the first step of OTP login.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(SendOtpRequested(_phoneController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpSent) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OtpVerificationPage(phone: state.phone),
            ));
          } else if (state is Authenticated) {
            // Covers the session restored from secure storage on app start —
            // the user goes straight to the home shell, not the login form.
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeShell()),
              (_) => false,
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.how_to_vote_outlined, size: 72),
                      const SizedBox(height: 12),
                      Text(
                        AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Raise your voice for your city.\nSign in with your phone number.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Send OTP'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
