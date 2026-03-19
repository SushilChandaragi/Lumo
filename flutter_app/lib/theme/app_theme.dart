// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary palette — deep forest green
  static const Color primary        = Color(0xFF2D6A4F);
  static const Color primaryLight   = Color(0xFF52B788);
  static const Color primarySurface = Color(0xFFD8F3DC);

  // Background & surface
  static const Color background     = Color(0xFFF7F8F5);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F1);

  // Text
  static const Color textPrimary    = Color(0xFF1A2E1F);
  static const Color textSecondary  = Color(0xFF6B7C72);
  static const Color textHint       = Color(0xFFADB5B8);

  // Status colors
  static const Color statusGreen    = Color(0xFF2D6A4F);
  static const Color statusAmber    = Color(0xFFD97706);
  static const Color statusRed      = Color(0xFFDC2626);

  // Misc
  static const Color divider        = Color(0xFFE8EDE9);
  static const Color cardBorder     = Color(0xFFE2E8E3);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness:       Brightness.light,
        primary:          AppColors.primary,
        onPrimary:        Color(0xFFFFFFFF),
        secondary:        AppColors.primaryLight,
        onSecondary:      Color(0xFFFFFFFF),
        error:            AppColors.statusRed,
        onError:          Color(0xFFFFFFFF),
        surface:          AppColors.surface,
        onSurface:        AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.8,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary, letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: AppColors.primary, letterSpacing: 0.1,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: AppColors.textSecondary, letterSpacing: 0.4,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:  AppColors.background,
        foregroundColor:  AppColors.textPrimary,
        elevation:        0,
        scrolledUnderElevation: 1,
        surfaceTintColor: AppColors.background,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color:         AppColors.surface,
        elevation:     0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:     AppColors.primary,
          foregroundColor:     Colors.white,
          elevation:           0,
          shadowColor:         Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
