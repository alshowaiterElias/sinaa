import 'package:flutter/material.dart';

import '../../config/theme.dart';

class LoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;
  final IconData? icon;
  final bool expanded;
  final bool outlined;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.text,
    this.icon,
    this.expanded = true,
    this.outlined = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final button = outlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: foregroundColor,
              side: BorderSide(
                color: foregroundColor ?? AppColors.primary,
                width: 2,
              ),
            ),
            child: _buildChild(context),
          )
        : Container(
            decoration: BoxDecoration(
              gradient:
                  isLoading || onPressed == null ? null : AppColors.primaryGradient,
              color: isLoading || onPressed == null
                  ? AppColors.divider
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isLoading || onPressed == null
                  ? null
                  : [
                      BoxShadow(
                        color: (backgroundColor ?? AppColors.primary)
                            .withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: foregroundColor ?? AppColors.textOnPrimary,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                disabledForegroundColor: AppColors.textTertiary,
              ),
              child: _buildChild(context),
            ),
          );

    return expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            outlined ? AppColors.primary : AppColors.textOnPrimary,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text),
          const SizedBox(width: 8),
          Icon(icon, size: 20),
        ],
      );
    }

    return Text(text);
  }
}

// Gradient Icon Button
class GradientIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double size;
  final LinearGradient? gradient;

  const GradientIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 56,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: gradient ?? AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.45,
        ),
      ),
    );
  }
}
