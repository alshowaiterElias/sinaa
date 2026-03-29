import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../shared/widgets/loading_button.dart';

class VerificationWaitingScreen extends ConsumerStatefulWidget {
  final String email;

  const VerificationWaitingScreen({Key? key, required this.email})
      : super(key: key);

  @override
  ConsumerState<VerificationWaitingScreen> createState() =>
      _VerificationWaitingScreenState();
}

class _VerificationWaitingScreenState
    extends ConsumerState<VerificationWaitingScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleResend() async {
    setState(() {
      _isResending = true;
    });

    final l10n = context.l10n;

    try {
      await ref
          .read(authStateProvider.notifier)
          .resendVerificationEmail(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tr('auth.verificationEmailSent')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _handleVerify() async {
    final l10n = context.l10n;

    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('auth.enterVerificationCode'))),
      );
      return;
    }

    try {
      await ref
          .read(authStateProvider.notifier)
          .verifyEmail(_codeController.text);

      // Refresh user data to update isVerified status
      await ref.read(authStateProvider.notifier).refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tr('auth.emailVerifiedSuccess')),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to home after successful verification
        context.go(Routes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleBackToLogin() async {
    // Logout to clear tokens and redirect to login
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.tr('auth.verifyYourEmail'),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '${l10n.tr('auth.verificationCodeSentTo')}\n${widget.email}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: l10n.tr('auth.verificationCode'),
                  hintText: l10n.tr('auth.enter6DigitCode'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                text: l10n.tr('auth.verify'),
                onPressed: _handleVerify,
                isLoading: authState.isLoading && !_isResending,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isResending ? null : _handleResend,
                child: _isResending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.tr('auth.resendEmail')),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _handleBackToLogin,
                child: Text(l10n.tr('auth.backToLogin')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
