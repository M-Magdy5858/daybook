import 'package:daybook/core/theme/app_colors.dart';
import 'package:daybook/core/theme/app_elevation.dart';
import 'package:daybook/core/theme/app_radius.dart';
import 'package:daybook/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: const CardThemeData(
        elevation: AppElevation.medium,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.small),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.small),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
      ),
    );
  }
}
