import 'package:flutter/material.dart';

/// Marmaradar design language: red / black / white.
abstract final class AppColors {
  static const red = Color(0xFFE8262D);
  static const redDark = Color(0xFFB3161C);
  static const night = Color(0xFF0B0B0D);
  static const surface = Color(0xFF161619);
  static const surfaceHigh = Color(0xFF212126);
  static const white = Color(0xFFF7F7F8);
  static const whiteMuted = Color(0xFFB9B9C0);
  static const outline = Color(0xFF2E2E34);
  static const success = Color(0xFF3DDC84);
  static const warning = Color(0xFFFFB300);

  /// Speed corridor road overlay.
  static const corridor = Color(0xFFFF8A00);

  /// Live Directions route overlay (distinct from corridor orange).
  static const route = Color(0xFF2B7FFF);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.red,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.redDark,
    onPrimaryContainer: AppColors.white,
    secondary: AppColors.white,
    onSecondary: AppColors.night,
    error: AppColors.red,
    onError: AppColors.white,
    surface: AppColors.surface,
    onSurface: AppColors.white,
    surfaceContainerHighest: AppColors.surfaceHigh,
    onSurfaceVariant: AppColors.whiteMuted,
    outline: AppColors.outline,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.night,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.white,
      displayColor: AppColors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.outline, width: 1.5),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: TextStyle(color: AppColors.white),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      labelStyle: const TextStyle(color: AppColors.whiteMuted),
      prefixIconColor: AppColors.whiteMuted,
      suffixIconColor: AppColors.whiteMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
    ),
  );
}
