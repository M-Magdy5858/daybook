import 'package:daybook/features/calendar/presentation/cubit/calendar_state.dart';
import 'package:daybook/features/calendar/presentation/views/move_event.dart';
import 'package:daybook/features/calendar/presentation/views/time_grid.dart';
import 'package:flutter/material.dart';

class DayView extends StatelessWidget {
  const DayView({super.key, required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context) => TimeGrid(
    days: [state.focused],
    occurrencesOn: state.on,
    onMoved: (o, start) => moveEvent(context, o, start),
  );
}
