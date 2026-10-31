import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/realtime/realtime_client.dart';
import '../../shared/widgets/marketplace_widgets.dart';

enum AuthMode { login, register, verify, recover, reset }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.apiClient,
    required this.realtimeClient,
    required this.onAuthenticated,
    super.key,
  });

  final ApiClient apiClient;
  final RealtimeClient realtimeClient;
  final VoidCallback onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode mode = AuthMode.login;
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final code = TextEditingController();
  bool busy = false;
  String? error;

  String get title => switch (mode) {
    AuthMode.login => 'Welcome back.',
    AuthMode.register => 'Create your account.',
    AuthMode.verify => 'Verify your email.',
    AuthMode.recover => 'Reset your password.',
    AuthMode.reset => 'Choose a new password.',
  };

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (mode == AuthMode.login) {
        await widget.apiClient.login(email.text.trim(), password.text);
        await _connectRealtime();
        if (mounted) {
          widget.onAuthenticated();
          context.go('/home');
        }
      } else if (mode == AuthMode.register) {
        await widget.apiClient.register(
          name: name.text.trim(),
          email: email.text.trim(),
          password: password.text,
        );
        if (mounted) {
          setState(() => mode = AuthMode.verify);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A verification code was sent to your email.'),
            ),
          );
        }
      } else if (mode == AuthMode.verify) {
        await widget.apiClient.verifyEmail(
          email: email.text.trim(),
          code: code.text.trim(),
        );
        if (mounted) setState(() => mode = AuthMode.login);
      } else if (mode == AuthMode.recover) {
        await widget.apiClient.requestPasswordReset(email.text.trim());
        if (mounted) {
          setState(() => mode = AuthMode.reset);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'If the account exists, a reset code is on its way.',
              ),
            ),
          );
        }
      } else {
        await widget.apiClient.resetPassword(
          token: code.text.trim(),
          password: password.text,
        );
        if (mounted) {
          setState(() => mode = AuthMode.login);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Password updated. Sign in with your new password.',
              ),
            ),
          );
        }
      }
    } on DioException catch (exception) {
      if (mounted) {
        setState(
          () => error =
              exception.message ?? 'The request could not be completed.',
        );
      }
    } on FormatException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PagePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 44),
              Text(
                'marketplace.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 46),
              Text(title, style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 10),
              Text(
                'Find trusted local professionals and manage every booking in one place.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              if (mode == AuthMode.register)
                TextField(
                  controller: name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
              if (mode == AuthMode.register) const SizedBox(height: 12),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email address'),
              ),
              if (mode == AuthMode.verify || mode == AuthMode.reset) ...[
                TextField(
                  controller: code,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: mode == AuthMode.verify
                        ? 'Email verification code'
                        : 'Password reset code',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (mode != AuthMode.recover) const SizedBox(height: 12),
              if (mode == AuthMode.login ||
                  mode == AuthMode.register ||
                  mode == AuthMode.reset)
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: mode == AuthMode.reset
                        ? 'New password'
                        : 'Password',
                  ),
                ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: busy ? null : submit,
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(switch (mode) {
                        AuthMode.recover => 'Send reset code',
                        AuthMode.verify => 'Verify email',
                        AuthMode.reset => 'Save new password',
                        _ => 'Continue',
                      }),
              ),
              if (mode == AuthMode.verify)
                Center(
                  child: TextButton(
                    onPressed: busy
                        ? null
                        : () async {
                            try {
                              await widget.apiClient.resendVerification(
                                email.text.trim(),
                              );
                            } on DioException catch (exception) {
                              if (mounted) {
                                setState(
                                  () => error =
                                      exception.message ??
                                      'The request could not be completed.',
                                );
                              }
                              return;
                            }
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'A new verification code was sent.',
                                ),
                              ),
                            );
                          },
                    child: const Text('Resend verification code'),
                  ),
                ),
              if (mode == AuthMode.login) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => mode = AuthMode.recover),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 22),
              Center(
                child: mode == AuthMode.login || mode == AuthMode.register
                    ? TextButton(
                        onPressed: () => setState(
                          () => mode = mode == AuthMode.register
                              ? AuthMode.login
                              : AuthMode.register,
                        ),
                        child: Text(
                          mode == AuthMode.register
                              ? 'Already have an account? Sign in'
                              : 'New here? Create an account',
                        ),
                      )
                    : TextButton(
                        onPressed: () => setState(() => mode = AuthMode.login),
                        child: const Text('Back to sign in'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connectRealtime() async {
    try {
      await widget.realtimeClient.connect();
    } on Object {
      // Authentication remains valid when the optional realtime service is down.
    }
  }
}

