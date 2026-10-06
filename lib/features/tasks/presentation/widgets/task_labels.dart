import 'package:daybook/core/theme/app_colors.dart';
import 'package:daybook/features/tasks/domain/entities/priority.dart';
import 'package:flutter/material.dart';

Color priorityColor(Priority p) => switch (p) {
  Priority.low => AppColors.priorityLow,
  Priority.medium => AppColors.priorityMedium,
  Priority.high => AppColors.priorityHigh,
};

String priorityLabel(Priority p) => switch (p) {
  Priority.low => 'Low',
  Priority.medium => 'Medium',
  Priority.high => 'High',
};

/// e.g. "Oct 6, 2026 · 9:00 AM" in the device's locale.
String formatDue(BuildContext context, DateTime due) {
  final l = MaterialLocalizations.of(context);
  final time = l.formatTimeOfDay(TimeOfDay.fromDateTime(due));
  return '${l.formatMediumDate(due)} · $time';
}
