import 'package:flutter/material.dart';

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

  static const corridor = Color(0xFFFF8A00);
  static const route = Color(0xFF2B7FFF);

  static const paper = Color(0xFFF4F4F6);
  static const paperSurface = Color(0xFFFFFFFF);
  static const paperHigh = Color(0xFFECECEF);
  static const ink = Color(0xFF121214);
  static const inkMuted = Color(0xFF5C5C66);
  static const paperOutline = Color(0xFFD8D8DE);
}

ThemeData buildDarkTheme() {
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
  return _finishTheme(
    scheme: scheme,
    scaffold: AppColors.night,
    body: AppColors.white,
    fieldFill: AppColors.surfaceHigh,
    fieldLabel: AppColors.whiteMuted,
    border: AppColors.outline,
  );
}

ThemeData buildLightTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.red,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.redDark,
    onPrimaryContainer: AppColors.white,
    secondary: AppColors.ink,
    onSecondary: AppColors.white,
    error: AppColors.red,
    onError: AppColors.white,
    surface: AppColors.paperSurface,
    onSurface: AppColors.ink,
    surfaceContainerHighest: AppColors.paperHigh,
    onSurfaceVariant: AppColors.inkMuted,
    outline: AppColors.paperOutline,
  );
  return _finishTheme(
    scheme: scheme,
    scaffold: AppColors.paper,
    body: AppColors.ink,
    fieldFill: AppColors.paperHigh,
    fieldLabel: AppColors.inkMuted,
    border: AppColors.paperOutline,
  );
}

ThemeData _finishTheme({
  required ColorScheme scheme,
  required Color scaffold,
  required Color body,
  required Color fieldFill,
  required Color fieldLabel,
  required Color border,
}) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffold,
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      backgroundColor: scaffold,
      foregroundColor: body,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: body,
      displayColor: body,
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
        foregroundColor: body,
        side: BorderSide(color: border, width: 1.5),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      contentTextStyle: TextStyle(color: body),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fieldFill,
      labelStyle: TextStyle(color: fieldLabel),
      prefixIconColor: fieldLabel,
      suffixIconColor: fieldLabel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
    ),
  );
}
