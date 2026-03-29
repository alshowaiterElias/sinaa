import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  /// 0 = email form, 1 = code + new password form, 2 = success
  int _step = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authStateProvider.notifier).forgotPassword(
            _emailController.text.trim(),
          );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _step = 1;
        });
        // Re-animate for the new step
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.resetPassword(
        email: _emailController.text.trim(),
        token: _codeController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _step = 2;
        });
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.warmGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    if (_step != 2)
                      IconButton(
                        onPressed: () {
                          if (_step == 1) {
                            setState(() => _step = 0);
                            _animationController.reset();
                            _animationController.forward();
                          } else {
                            context.pop();
                          }
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _step == 0
                          ? _buildEmailForm()
                          : _step == 1
                              ? _buildCodeAndPasswordForm()
                              : _buildSuccessContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        // Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            size: 48,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 32),

        // Title
        Text(
          l10n.tr('auth.forgotPasswordTitle'),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 12),

        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.tr('auth.forgotPasswordSubtitle'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 40),

        // Form
        Form(
          key: _emailFormKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _emailController,
                label: l10n.tr('auth.email'),
                hint: 'example@email.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (value) => Validators.email(value),
              ),
              const SizedBox(height: 32),
              LoadingButton(
                onPressed: _handleSendCode,
                isLoading: _isLoading,
                text: l10n.tr('auth.sendResetLink'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Back to login
        TextButton(
          onPressed: () => context.pop(),
          child: Text(l10n.tr('auth.backToLogin')),
        ),
      ],
    );
  }

  Widget _buildCodeAndPasswordForm() {
    final l10n = context.l10n;
    final isRtl = context.isRtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        // Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.pin_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 32),

        // Title
        Text(
          isRtl ? 'أدخل رمز التحقق' : 'Enter Reset Code',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 12),

        // Subtitle with email
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            isRtl
                ? 'تم إرسال رمز تحقق إلى\n${_emailController.text.trim()}'
                : 'A reset code was sent to\n${_emailController.text.trim()}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 12),

        // Check spam tip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRtl
                      ? 'تحقق من مجلد البريد العشوائي (Spam) إذا لم تجد الرسالة'
                      : 'Check your spam folder if you don\'t see the email',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Form
        Form(
          key: _resetFormKey,
          child: Column(
            children: [
              // Code entry
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: isRtl ? 'رمز التحقق' : 'Reset Code',
                  hintText: isRtl ? 'أدخل الرمز المكون من 6 أرقام' : 'Enter 6-digit code',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.pin_outlined),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
              ),

              const SizedBox(height: 20),

              // New password
              CustomTextField(
                controller: _passwordController,
                label: l10n.tr('auth.newPassword'),
                hint: 'Abc12345',
                obscureText: _obscurePassword,
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textTertiary,
                  ),
                ),
                validator: (value) => Validators.password(value),
              ),

              // Password requirements hint
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 4),
                child: Text(
                  l10n.tr('auth.passwordRequirements'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ),

              const SizedBox(height: 20),

              // Confirm password
              CustomTextField(
                controller: _confirmPasswordController,
                label: l10n.tr('auth.confirmPassword'),
                hint: '••••••••',
                obscureText: _obscureConfirmPassword,
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textTertiary,
                  ),
                ),
                validator: (value) =>
                    Validators.confirmPassword(value, _passwordController.text),
              ),

              const SizedBox(height: 32),

              LoadingButton(
                onPressed: _handleResetPassword,
                isLoading: _isLoading,
                text: l10n.tr('auth.setPassword'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Resend code
        TextButton(
          onPressed: _isLoading ? null : _handleSendCode,
          child: Text(isRtl ? 'إعادة إرسال الرمز' : 'Resend Code'),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),

        // Success icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 60,
            color: AppColors.success,
          ),
        ),

        const SizedBox(height: 32),

        // Title
        Text(
          l10n.tr('auth.successTitle'),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
        ),

        const SizedBox(height: 16),

        // Message
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.tr('auth.passwordChangedSuccess'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 40),

        // Login button
        LoadingButton(
          onPressed: () => context.go('/login'),
          isLoading: false,
          text: l10n.tr('auth.login'),
        ),
      ],
    );
  }
}
