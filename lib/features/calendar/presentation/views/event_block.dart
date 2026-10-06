import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A colored block for one occurrence. Tap to edit the event.
class EventBlock extends StatelessWidget {
  const EventBlock({super.key, required this.occurrence, this.compact = false});

  final EventOccurrence occurrence;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final event = occurrence.event;
    final color = Color(event.colorValue);
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(occurrence.start));

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => context.push(Routes.eventDetail(event.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          child: Text(
            compact || event.allDay ? event.title : '${event.title}\n$time',
            maxLines: compact ? 1 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: onColor, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
