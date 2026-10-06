import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/features/calendar/presentation/views/event_block.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:flutter/material.dart';

const hourHeight = 48.0;
const _pixelsPerMinute = hourHeight / 60;
const _snapMinutes = 15;
const _labelWidth = 44.0;

/// Called when an occurrence is dropped on a new start time.
typedef OnEventMoved =
    void Function(EventOccurrence occurrence, DateTime newStart);

/// Where each timed occurrence goes: overlapping occurrences share the width,
/// side by side. Greedy: each one takes the first column that's free.
List<({EventOccurrence occurrence, int column, int columns})> layoutOverlaps(
  List<EventOccurrence> occurrences,
) {
  final sorted = [...occurrences]..sort((a, b) => a.start.compareTo(b.start));
  final result = <({EventOccurrence occurrence, int column, int columns})>[];
  var cluster = <(EventOccurrence, int)>[];
  var columnEnds = <DateTime>[];

  void closeCluster() {
    for (final (o, col) in cluster) {
      result.add((occurrence: o, column: col, columns: columnEnds.length));
    }
    cluster = [];
    columnEnds = [];
  }

  for (final o in sorted) {
    // A new cluster starts once nothing still running overlaps this one.
    if (columnEnds.isNotEmpty && columnEnds.every((e) => !e.isAfter(o.start))) {
      closeCluster();
    }
    var col = columnEnds.indexWhere((e) => !e.isAfter(o.start));
    if (col == -1) {
      col = columnEnds.length;
      columnEnds.add(o.end);
    } else {
      columnEnds[col] = o.end;
    }
    cluster.add((o, col));
  }
  closeCluster();
  return result;
}

/// Hour labels plus one column per day in [days]; used by the day and week
/// views. All-day events sit in a strip above the grid.
class TimeGrid extends StatefulWidget {
  const TimeGrid({
    super.key,
    required this.days,
    required this.occurrencesOn,
    required this.onMoved,
    this.showDayHeaders = false,
  });

  final List<DateTime> days;
  final List<EventOccurrence> Function(DateTime day) occurrencesOn;
  final OnEventMoved onMoved;
  final bool showDayHeaders;

  @override
  State<TimeGrid> createState() => _TimeGridState();
}

class _TimeGridState extends State<TimeGrid> {
  // Start the morning in view rather than midnight.
  final _scroll = ScrollController(initialScrollOffset: 7 * hourHeight);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allDay = [
      for (final day in widget.days)
        [
          for (final o in widget.occurrencesOn(day))
            if (o.event.allDay) o,
        ],
    ];
    final hasAllDay = allDay.any((l) => l.isNotEmpty);

    return Column(
      children: [
        if (widget.showDayHeaders) _DayHeaders(days: widget.days),
        if (hasAllDay)
          Row(
            children: [
              const SizedBox(width: _labelWidth),
              for (final list in allDay)
                Expanded(
                  child: Column(
                    children: [
                      for (final o in list)
                        Padding(
                          padding: const EdgeInsets.all(1),
                          child: EventBlock(occurrence: o, compact: true),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            child: SizedBox(
              height: 24 * hourHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HourLabels(),
                  for (final day in widget.days)
                    Expanded(
                      child: _DayColumn(
                        day: day,
                        occurrences: [
                          for (final o in widget.occurrencesOn(day))
                            if (!o.event.allDay) o,
                        ],
                        onMoved: widget.onMoved,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayHeaders extends StatelessWidget {
  const _DayHeaders({required this.days});

  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final l = MaterialLocalizations.of(context);
    final today = DateTime.now();
    return Row(
      children: [
        const SizedBox(width: _labelWidth),
        for (final d in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: [
                  Text(
                    l.narrowWeekdays[d.weekday % 7],
                    style: context.text.labelSmall,
                  ),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontWeight: d.isSameDay(today) ? FontWeight.bold : null,
                      color: d.isSameDay(today) ? context.colors.primary : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HourLabels extends StatelessWidget {
  const _HourLabels();

  @override
  Widget build(BuildContext context) {
    final l = MaterialLocalizations.of(context);
    return SizedBox(
      width: _labelWidth,
      child: Column(
        children: [
          for (var h = 0; h < 24; h++)
            SizedBox(
              height: hourHeight,
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                  child: Text(
                    l.formatTimeOfDay(
                      TimeOfDay(hour: h, minute: 0),
                      alwaysUse24HourFormat: true,
                    ),
                    style: context.text.labelSmall,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One day of the grid. Events can be long-pressed and dropped here; the
/// drop snaps to 15-minute slots.
class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.occurrences,
    required this.onMoved,
  });

  final DateTime day;
  final List<EventOccurrence> occurrences;
  final OnEventMoved onMoved;

  DateTime _snap(BuildContext context, Offset globalTopLeft) {
    final box = context.findRenderObject()! as RenderBox;
    final minutes = (box.globalToLocal(globalTopLeft).dy / _pixelsPerMinute)
        .round();
    final snapped = ((minutes / _snapMinutes).round() * _snapMinutes).clamp(
      0,
      24 * 60 - _snapMinutes,
    );
    return DateTime(day.year, day.month, day.day, 0, snapped);
  }

  @override
  Widget build(BuildContext context) {
    final dayStart = day.startOfDay;
    return DragTarget<EventOccurrence>(
      onAcceptWithDetails: (details) =>
          onMoved(details.data, _snap(context, details.offset)),
      builder: (context, candidates, _) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            children: [
              // Hour lines.
              for (var h = 0; h < 24; h++)
                Positioned(
                  top: h * hourHeight,
                  left: 0,
                  right: 0,
                  child: Divider(
                    height: 1,
                    color: context.colors.outlineVariant,
                  ),
                ),
              if (candidates.isNotEmpty)
                Positioned.fill(
                  child: ColoredBox(
                    color: context.colors.primary.withValues(alpha: 0.05),
                  ),
                ),
              for (final (:occurrence, :column, :columns) in layoutOverlaps(
                occurrences,
              ))
                _positioned(occurrence, column, columns, width, dayStart),
            ],
          );
        },
      ),
    );
  }

  Widget _positioned(
    EventOccurrence o,
    int column,
    int columns,
    double width,
    DateTime dayStart,
  ) {
    // Clip to this day, so an event crossing midnight shows on both days.
    final top = o.start.isBefore(dayStart)
        ? 0
        : o.start.difference(dayStart).inMinutes;
    final bottom = o.end.difference(dayStart).inMinutes.clamp(0, 24 * 60);
    final height = ((bottom - top) * _pixelsPerMinute).clamp(
      18.0,
      24 * hourHeight,
    );
    final blockWidth = width / columns;
    final block = SizedBox(
      width: blockWidth - 2,
      height: height - 2,
      child: EventBlock(occurrence: o, compact: height < 36),
    );

    return PositionedDirectional(
      top: top * _pixelsPerMinute + 1,
      start: column * blockWidth + 1,
      child: LongPressDraggable<EventOccurrence>(
        data: o,
        // The preview is just the block itself, so nothing else rebuilds
        // while dragging.
        feedback: Opacity(opacity: 0.85, child: block),
        childWhenDragging: Opacity(opacity: 0.3, child: block),
        child: block,
      ),
    );
  }
}
