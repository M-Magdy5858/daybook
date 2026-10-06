import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/calendar/presentation/cubit/calendar_cubit.dart';
import 'package:daybook/features/calendar/presentation/cubit/calendar_state.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A 7-column grid of the month. Empty cells before the 1st line days up
/// with their weekday. Tap a day to open it in the day view.
class MonthView extends StatelessWidget {
  const MonthView({super.key, required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context) {
    final first = state.focused.startOfMonth;
    final leadingBlanks = first.weekday - 1; // weeks start on Monday
    final cells = ((leadingBlanks + first.daysInMonth) / 7).ceil() * 7;
    final l = MaterialLocalizations.of(context);

    return Column(
      children: [
        Row(
          children: [
            for (var d = DateTime.monday; d <= DateTime.sunday; d++)
              Expanded(
                child: Center(
                  child: Text(
                    l.narrowWeekdays[d % 7],
                    style: context.text.labelMedium,
                  ),
                ),
              ),
          ],
        ),
        AppSpacing.gapXs,
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.85,
            ),
            itemCount: cells,
            itemBuilder: (context, i) {
              final dayNumber = i - leadingBlanks + 1;
              if (dayNumber < 1 || dayNumber > first.daysInMonth) {
                return const SizedBox.shrink();
              }
              return _DayCell(
                date: DateTime(first.year, first.month, dayNumber),
                state: state,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.date, required this.state});

  final DateTime date;
  final CalendarState state;

  @override
  Widget build(BuildContext context) {
    final events = state.on(date);
    final isToday = date.isSameDay(DateTime.now());
    final isSelected = date.isSameDay(state.selected);
    final colors = context.colors;
    final count = events.length;

    return Semantics(
      button: true,
      label:
          '${MaterialLocalizations.of(context).formatFullDate(date)}, '
          '${count == 1 ? '1 event' : '$count events'}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.read<CalendarCubit>().openDay(date),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? colors.primary : null,
                border: isSelected && !isToday
                    ? Border.all(color: colors.primary)
                    : null,
              ),
              child: Text(
                '${date.day}',
                style: TextStyle(color: isToday ? colors.onPrimary : null),
              ),
            ),
            AppSpacing.gapXs,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final o in events.take(3))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: CircleAvatar(
                      radius: 3,
                      backgroundColor: Color(o.event.colorValue),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
