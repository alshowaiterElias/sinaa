import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../projects/screens/location_picker_screen.dart';
import '../../projects/widgets/social_links_editor.dart';
import '../../projects/widgets/working_hours_editor.dart';

class ProjectOwnerRegisterScreen extends ConsumerStatefulWidget {
  const ProjectOwnerRegisterScreen({super.key});

  @override
  ConsumerState<ProjectOwnerRegisterScreen> createState() =>
      _ProjectOwnerRegisterScreenState();
}

class _ProjectOwnerRegisterScreenState
    extends ConsumerState<ProjectOwnerRegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _projectNameController = TextEditingController();
  final _projectNameArController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionArController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedCity = '';
  double? _latitude;
  double? _longitude;
  Map<String, String>? _workingHours;
  Map<String, String>? _socialLinks;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _projectNameController.dispose();
    _projectNameArController.dispose();
    _descriptionController.dispose();
    _descriptionArController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authStateProvider.notifier).registerProjectOwner(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            projectName: _projectNameController.text.trim(),
            projectNameAr: _projectNameArController.text.trim(),
            city: _selectedCity,
            description: _descriptionController.text.trim(),
            descriptionAr: _descriptionArController.text.trim(),
            latitude: _latitude,
            longitude: _longitude,
            workingHours: _workingHours,
            socialLinks: _socialLinks,
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
          );

      if (mounted) {
        context.go(Routes.home);
      }
    } catch (e) {
      if (mounted) {
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
    final authState = ref.watch(authStateProvider);
    final l10n = context.l10n;

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
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.tr('auth.projectOwner'),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),

              // Progress indicator
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: List.generate(2, (index) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: index <= _currentStep
                              ? AppColors.primaryGradient
                              : null,
                          color:
                              index <= _currentStep ? null : AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Header
                          Text(
                            _currentStep == 0
                                ? l10n.tr('auth.projectInfo')
                                : l10n.tr('auth.accountInfo'),
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            _currentStep == 0
                                ? l10n.tr('auth.projectInfoSubtitle')
                                : l10n.tr('auth.accountInfoSubtitle'),
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),

                          const SizedBox(height: 32),

                          if (_currentStep == 0) ...[
                            // Project info
                            CustomTextField(
                              controller: _projectNameController,
                              label: l10n.tr('auth.projectName'),
                              hint: 'My Family Project',
                              textCapitalization: TextCapitalization.words,
                              prefixIcon: Icons.storefront_rounded,
                              validator: (value) =>
                                  Validators.projectName(value),
                            ),

                            const SizedBox(height: 20),

                            CustomTextField(
                              controller: _projectNameArController,
                              label: l10n.tr('auth.projectNameAr'),
                              hint: 'مشروعي العائلي',
                              prefixIcon: Icons.storefront_rounded,
                              validator: (value) =>
                                  Validators.projectName(value),
                            ),

                            const SizedBox(height: 20),

                            // Description
                            CustomTextField(
                              controller: _descriptionController,
                              label: l10n.tr('project.descriptionEn'),
                              hint: 'Describe your project...',
                              maxLines: 3,
                              prefixIcon: Icons.description_outlined,
                            ),

                            const SizedBox(height: 20),

                            CustomTextField(
                              controller: _descriptionArController,
                              label: l10n.tr('project.descriptionAr'),
                              hint: 'وصف مشروعك...',
                              maxLines: 3,
                              prefixIcon: Icons.description_outlined,
                            ),

                            const SizedBox(height: 20),

                            // Location Picker
                            _RegisterTile(
                              icon: Icons.location_on_outlined,
                              title: l10n.tr('project.location'),
                              subtitle: _selectedCity.isNotEmpty
                                  ? _selectedCity
                                  : l10n.tr('project.pickLocation'),
                              onTap: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LocationPickerScreen(),
                                  ),
                                );

                                if (result != null && mounted) {
                                  setState(() {
                                    _latitude = result['latitude'];
                                    _longitude = result['longitude'];
                                    if (result['city'] != null) {
                                      _selectedCity = result['city'];
                                    }
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 12),

                            // Working Hours
                            _RegisterTile(
                              icon: Icons.access_time,
                              title: l10n.tr('project.workingHours'),
                              subtitle: _workingHours != null
                                  ? l10n.tr('common.done')
                                  : l10n.tr('project.workingHoursSubtitle'),
                              onTap: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => WorkingHoursEditor(
                                      initialValue: _workingHours,
                                      isSelectionMode: true,
                                    ),
                                  ),
                                );

                                if (result != null && mounted) {
                                  setState(() {
                                    _workingHours = result;
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 12),

                            // Social Links
                            _RegisterTile(
                              icon: Icons.link,
                              title: l10n.tr('project.socialLinks'),
                              subtitle: _socialLinks != null
                                  ? l10n.tr('common.done')
                                  : l10n.tr('project.socialLinksSubtitle'),
                              onTap: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SocialLinksEditor(
                                      initialValue: _socialLinks,
                                      isSelectionMode: true,
                                    ),
                                  ),
                                );

                                if (result != null && mounted) {
                                  setState(() {
                                    _socialLinks = result;
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 32),

                            // Next button
                            LoadingButton(
                              onPressed: () {
                                if (_projectNameController.text.isEmpty ||
                                    _projectNameArController.text.isEmpty ||
                                    _selectedCity.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text(l10n.tr('auth.fillAllFields')),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setState(() {
                                  _currentStep = 1;
                                });
                              },
                              isLoading: false,
                              text: l10n.tr('auth.next'),
                              icon: Icons.arrow_forward_rounded,
                            ),
                          ] else ...[
                            // Account info
                            CustomTextField(
                              controller: _fullNameController,
                              label: l10n.tr('auth.fullName'),
                              hint: l10n.tr('auth.enterFullName'),
                              prefixIcon: Icons.person_outline_rounded,
                              textCapitalization: TextCapitalization.words,
                              validator: (value) => Validators.fullName(value),
                            ),

                            const SizedBox(height: 20),

                            CustomTextField(
                              controller: _emailController,
                              label: l10n.tr('auth.email'),
                              hint: 'example@email.com',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              validator: (value) => Validators.email(value),
                            ),

                            const SizedBox(height: 20),

                            CustomTextField(
                              controller: _phoneController,
                              label: l10n.tr('auth.phone'),
                              hint: '05xxxxxxxx',
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_outlined,
                              validator: (value) =>
                                  Validators.saudiPhone(value, required: true),
                            ),

                            const SizedBox(height: 20),

                            CustomTextField(
                              controller: _passwordController,
                              label: l10n.tr('auth.password'),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            CustomTextField(
                              controller: _confirmPasswordController,
                              label: l10n.tr('auth.confirmPassword'),
                              hint: '••••••••',
                              obscureText: _obscureConfirmPassword,
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              validator: (value) => Validators.confirmPassword(
                                  value, _passwordController.text),
                            ),

                            const SizedBox(height: 32),

                            // Buttons row
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _currentStep = 0;
                                      });
                                    },
                                    child: Text(l10n.tr('auth.previous')),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: LoadingButton(
                                    onPressed: _handleRegister,
                                    isLoading: authState.isLoading,
                                    text: l10n.tr('auth.createAccount'),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 32),
                        ],
                      ),
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
}

class _RegisterTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RegisterTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
