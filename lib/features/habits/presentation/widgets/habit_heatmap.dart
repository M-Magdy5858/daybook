import 'package:daybook/features/habits/domain/entities/habit.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:flutter/material.dart';

const _weeks = 53;
const _cell = 14.0;
const _gap = 3.0;
const _step = _cell + _gap;

/// A GitHub-style year: one column per week (oldest on the left), one row
/// per weekday (Monday on top). Darker squares are done days. Tap a square
/// to toggle that day.
class HabitHeatmap extends StatelessWidget {
  const HabitHeatmap({
    super.key,
    required this.habit,
    required this.today,
    required this.onToggle,
  });

  final Habit habit;
  final DateTime today;
  final ValueChanged<DateTime> onToggle;

  /// The Monday of the leftmost column.
  DateTime get _firstMonday =>
      today.startOfDay.startOfWeek.addDays(-7 * (_weeks - 1));

  DateTime? _dateAt(Offset local) {
    final col = local.dx ~/ _step;
    final row = local.dy ~/ _step;
    if (col < 0 || col >= _weeks || row < 0 || row > 6) return null;
    final date = _firstMonday.addDays(col * 7 + row);
    return date.isAfter(today) ? null : date;
  }

  @override
  Widget build(BuildContext context) {
    final done = habit.completions
        .where((d) => !d.isBefore(_firstMonday))
        .length;
    return Semantics(
      label: '${habit.name}: done $done days in the past year',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true, // start on the current week
        child: GestureDetector(
          onTapUp: (details) {
            final date = _dateAt(details.localPosition);
            if (date != null) onToggle(date);
          },
          child: CustomPaint(
            size: const Size(_weeks * _step - _gap, 7 * _step - _gap),
            painter: _HeatmapPainter(
              habit: habit,
              firstMonday: _firstMonday,
              today: today.startOfDay,
              doneColor: Color(habit.colorValue),
              emptyColor: context.colors.surfaceContainerHighest,
              todayBorder: context.colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.habit,
    required this.firstMonday,
    required this.today,
    required this.doneColor,
    required this.emptyColor,
    required this.todayBorder,
  });

  final Habit habit;
  final DateTime firstMonday;
  final DateTime today;
  final Color doneColor;
  final Color emptyColor;
  final Color todayBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final done = Paint()..color = doneColor;
    final scheduled = Paint()..color = emptyColor;
    // Days it isn't scheduled on are paler, so a gap there reads as fine.
    final unscheduled = Paint()..color = emptyColor.withValues(alpha: 0.35);
    final border = Paint()
      ..color = todayBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var col = 0; col < _weeks; col++) {
      for (var row = 0; row < 7; row++) {
        final date = firstMonday.addDays(col * 7 + row);
        if (date.isAfter(today)) continue; // the future stays blank
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(col * _step, row * _step, _cell, _cell),
          const Radius.circular(3),
        );
        canvas.drawRRect(
          rect,
          habit.isDoneOn(date)
              ? done
              : habit.isScheduledOn(date)
              ? scheduled
              : unscheduled,
        );
        if (date == today) canvas.drawRRect(rect, border);
      }
    }
  }

  // Redraw only when the data or colors change, not on every frame.
  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.habit != habit ||
      old.today != today ||
      old.doneColor != doneColor ||
      old.emptyColor != emptyColor;
}
