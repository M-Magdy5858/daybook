import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFFE65100);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color info = Color(0xFF1565C0);

  static const Color priorityLow = Color(0xFF78909C);
  static const Color priorityMedium = Color(0xFF1E88E5);
  static const Color priorityHigh = Color(0xFFD84315);

  static const List<Color> chart = [
    Color(0xFFE65100),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFF8E24AA),
    Color(0xFFFDD835),
    Color(0xFF00ACC1),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
  ];
}
