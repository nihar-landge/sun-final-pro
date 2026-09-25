import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/utils/validators.dart';
import 'package:feedback_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:feedback_app/features/home_shell.dart';

/// Second step of OTP login: enter the 6-digit code (and name on first login).
class OtpVerificationPage extends StatefulWidget {
  final String phone;
  final String? devOtp;

  const OtpVerificationPage({super.key, required this.phone, this.devOtp});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(OtpVerificationRequested(
          phone: widget.phone,
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
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
                      Text(
                        'We sent a code to ${widget.phone}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (widget.devOtp != null) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _codeController.text = widget.devOtp!,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .tertiaryContainer
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.developer_mode, size: 16),
                                const SizedBox(width: 8),
                                Text('Dev OTP: ${widget.devOtp} — tap to fill',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: '6-digit OTP',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator: Validators.otp,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Your name (new users)',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? null : Validators.name(value),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Verify & Sign in'),
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
