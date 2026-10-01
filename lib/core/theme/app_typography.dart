import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const TextTheme textTheme = TextTheme(
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );
}
