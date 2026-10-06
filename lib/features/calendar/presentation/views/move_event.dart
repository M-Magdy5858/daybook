import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/features/calendar/presentation/cubit/calendar_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _MoveScope { thisEvent, allEvents }

/// Saves a drag-to-reschedule. For a repeating event, asks first whether to
/// move just this occurrence or the whole series.
Future<void> moveEvent(
  BuildContext context,
  EventOccurrence occurrence,
  DateTime newStart,
) async {
  if (newStart == occurrence.start) return;
  final cubit = context.read<CalendarCubit>();
  if (!occurrence.isRepeating) {
    return cubit.moveEvent(occurrence, newStart);
  }
  final scope = await showDialog<_MoveScope>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Move repeating event'),
      content: const Text(
        'Move only this event, or every event in the series?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _MoveScope.thisEvent),
          child: const Text('This event'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _MoveScope.allEvents),
          child: const Text('All events'),
        ),
      ],
    ),
  );
  if (scope == null) return;
  await cubit.moveEvent(
    occurrence,
    newStart,
    wholeSeries: scope == _MoveScope.allEvents,
  );
}
