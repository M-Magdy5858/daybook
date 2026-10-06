import 'package:daybook/features/calendar/presentation/cubit/calendar_state.dart';
import 'package:daybook/features/calendar/presentation/views/move_event.dart';
import 'package:daybook/features/calendar/presentation/views/time_grid.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:flutter/material.dart';

class WeekView extends StatelessWidget {
  const WeekView({super.key, required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context) {
    final monday = state.focused.startOfWeek;
    return TimeGrid(
      days: [for (var i = 0; i < 7; i++) monday.addDays(i)],
      occurrencesOn: state.on,
      onMoved: (o, start) => moveEvent(context, o, start),
      showDayHeaders: true,
    );
  }
}
