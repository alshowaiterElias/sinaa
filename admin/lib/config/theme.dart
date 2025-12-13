import 'package:flutter/material.dart';

/// Admin panel color palette
class AdminColors {
  AdminColors._();

  // Primary - Professional blue
  static const Color primary = Color(0xFF1E3A5F);
  static const Color primaryLight = Color(0xFF2C5282);
  static const Color primaryDark = Color(0xFF152A45);

  // Secondary - Teal accent
  static const Color secondary = Color(0xFF319795);
  static const Color secondaryLight = Color(0xFF4FD1C5);
  static const Color secondaryDark = Color(0xFF1D6F6D);

  // Accent - Gold
  static const Color accent = Color(0xFFD69E2E);
  static const Color accentLight = Color(0xFFF6E05E);
  static const Color accentDark = Color(0xFFA67C00);

  // Background
  static const Color background = Color(0xFFF7FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEDF2F7);

  // Text
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textTertiary = Color(0xFFA0AEC0);

  // Status
  static const Color success = Color(0xFF38A169);
  static const Color warning = Color(0xFFD69E2E);
  static const Color error = Color(0xFFE53E3E);
  static const Color info = Color(0xFF3182CE);

  // Others
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x1A1A202C);

  // Sidebar
  static const Color sidebarBg = Color(0xFF1E3A5F);
  static const Color sidebarText = Color(0xFFE2E8F0);
  static const Color sidebarActive = Color(0xFF319795);

  // Status Badge Colors
  static const Color pendingBg = Color(0xFFFEF3C7);
  static const Color pendingText = Color(0xFF92400E);
  static const Color approvedBg = Color(0xFFD1FAE5);
  static const Color approvedText = Color(0xFF065F46);
  static const Color rejectedBg = Color(0xFFFEE2E2);
  static const Color rejectedText = Color(0xFF991B1B);
}

/// Admin panel theme
class AdminTheme {
  AdminTheme._();

  static const String fontFamily = 'Cairo';

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.light,

      colorScheme: const ColorScheme.light(
        primary: AdminColors.primary,
        onPrimary: Colors.white,
        secondary: AdminColors.secondary,
        onSecondary: Colors.white,
        tertiary: AdminColors.accent,
        surface: AdminColors.surface,
        onSurface: AdminColors.textPrimary,
        error: AdminColors.error,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: AdminColors.background,

      appBarTheme: const AppBarTheme(
        backgroundColor: AdminColors.surface,
        foregroundColor: AdminColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AdminColors.textPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        color: AdminColors.surface,
        elevation: 1,
        shadowColor: AdminColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.primary,
          side: const BorderSide(color: AdminColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AdminColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AdminColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AdminColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AdminColors.error),
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AdminColors.textSecondary,
        ),
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AdminColors.surfaceVariant),
        headingTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          color: AdminColors.textPrimary,
        ),
        dataTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AdminColors.textPrimary,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AdminColors.surfaceVariant,
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      dividerTheme: const DividerThemeData(
        color: AdminColors.divider,
        thickness: 1,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AdminColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AdminColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AdminColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AdminColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AdminColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AdminColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AdminColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AdminColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AdminColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AdminColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AdminColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AdminColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AdminColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AdminColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AdminColors.textTertiary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: AdminColors.primaryLight,
        secondary: AdminColors.secondaryLight,
        tertiary: AdminColors.accentLight,
        surface: Color(0xFF1A202C),
        error: AdminColors.error,
      ),

      scaffoldBackgroundColor: const Color(0xFF0D1117),
    );
  }
}
