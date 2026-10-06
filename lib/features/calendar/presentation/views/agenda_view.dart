import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/features/calendar/presentation/cubit/calendar_state.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:daybook/shared/widgets/app_states.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The next 30 days as a list, grouped by date.
class AgendaView extends StatelessWidget {
  const AgendaView({super.key, required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context) {
    final (from, _) = state.range;
    final days = [
      for (var i = 0; i < 30; i++)
        if (state.on(from.addDays(i)) case final list when list.isNotEmpty)
          (from.addDays(i), list),
    ];
    if (days.isEmpty) {
      return const AppEmptyState(
        title: 'Nothing coming up',
        message: 'No events in the next 30 days.',
        icon: Icons.event_available,
      );
    }
    final l = MaterialLocalizations.of(context);
    return ListView(
      children: [
        for (final (day, list) in days) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(l.formatFullDate(day), style: context.text.titleSmall),
          ),
          for (final o in list) _AgendaTile(occurrence: o),
        ],
      ],
    );
  }
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({required this.occurrence});

  final EventOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final event = occurrence.event;
    final l = MaterialLocalizations.of(context);
    String time(DateTime d) => l.formatTimeOfDay(TimeOfDay.fromDateTime(d));
    return ListTile(
      leading: Container(width: 4, height: 32, color: Color(event.colorValue)),
      title: Text(event.title),
      subtitle: Text(
        event.allDay
            ? 'All day'
            : '${time(occurrence.start)} – ${time(occurrence.end)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (event.linkedTaskId != null)
            const Tooltip(
              message: 'Scheduled from a task',
              child: Icon(Icons.task_alt, size: 18),
            ),
          if (occurrence.isRepeating)
            const Tooltip(
              message: 'Repeats',
              child: Icon(Icons.repeat, size: 18),
            ),
        ],
      ),
      onTap: () => context.push(Routes.eventDetail(event.id)),
    );
  }
}
