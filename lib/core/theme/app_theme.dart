import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary700,
        primary: AppColors.primary700,
        onPrimary: Colors.white,
        secondary: AppColors.gold500,
        surface: AppColors.surface,
        error: AppColors.danger700,
        brightness: Brightness.light,
      ),
    );

    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text900,
      displayColor: AppColors.text900,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: textTheme,
      splashColor: AppColors.primary100,
      highlightColor: AppColors.primary50,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text900,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.text900,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.text500),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.text900,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary700;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.border, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary900,
        contentTextStyle: GoogleFonts.cairo(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary600,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
