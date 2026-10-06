import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/shared/models/recurrence_rule.dart';
import 'package:flutter/material.dart';

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String weekdayName(int weekday) => _weekdayNames[weekday - 1];

String describeRecurrence(RecurrenceRule rule) => switch (rule) {
  Daily() => 'Every day',
  EveryNDays(:final n) => n == 1 ? 'Every day' : 'Every $n days',
  Weekly(:final weekdays) =>
    'Weekly on ${(weekdays.toList()..sort()).map(weekdayName).join(', ')}',
  Monthly(:final day) => 'Monthly on day $day',
};

enum _Kind { none, daily, weekly, monthly, everyNDays }

/// Opens a bottom sheet to pick how a task repeats. Returns `null` if the
/// sheet was dismissed, or a record holding the choice (which may be `null`
/// for "doesn't repeat").
Future<(RecurrenceRule?,)?> showRecurrencePicker(
  BuildContext context, {
  RecurrenceRule? initial,
  required DateTime anchor,
}) => showModalBottomSheet<(RecurrenceRule?,)>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _RecurrenceSheet(initial: initial, anchor: anchor),
);

class _RecurrenceSheet extends StatefulWidget {
  const _RecurrenceSheet({required this.initial, required this.anchor});

  final RecurrenceRule? initial;
  final DateTime anchor;

  @override
  State<_RecurrenceSheet> createState() => _RecurrenceSheetState();
}

class _RecurrenceSheetState extends State<_RecurrenceSheet> {
  late _Kind _kind = switch (widget.initial) {
    null => _Kind.none,
    Daily() => _Kind.daily,
    Weekly() => _Kind.weekly,
    Monthly() => _Kind.monthly,
    EveryNDays() => _Kind.everyNDays,
  };
  late Set<int> _weekdays = switch (widget.initial) {
    Weekly(:final weekdays) => {...weekdays},
    _ => {widget.anchor.weekday},
  };
  late int _n = switch (widget.initial) {
    EveryNDays(:final n) => n,
    _ => 2,
  };

  RecurrenceRule? get _rule => switch (_kind) {
    _Kind.none => null,
    _Kind.daily => const Daily(),
    _Kind.weekly => Weekly(_weekdays),
    _Kind.monthly => Monthly(widget.anchor.day),
    _Kind.everyNDays => EveryNDays(_n),
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Repeat', style: Theme.of(context).textTheme.titleLarge),
            AppSpacing.gapSm,
            RadioGroup<_Kind>(
              groupValue: _kind,
              onChanged: (k) => setState(() => _kind = k!),
              child: Column(
                children: [
                  const RadioListTile(
                    value: _Kind.none,
                    title: Text("Doesn't repeat"),
                  ),
                  const RadioListTile(
                    value: _Kind.daily,
                    title: Text('Every day'),
                  ),
                  const RadioListTile(
                    value: _Kind.weekly,
                    title: Text('Weekly'),
                  ),
                  RadioListTile(
                    value: _Kind.monthly,
                    title: Text('Monthly on day ${widget.anchor.day}'),
                  ),
                  const RadioListTile(
                    value: _Kind.everyNDays,
                    title: Text('Every few days'),
                  ),
                ],
              ),
            ),
            if (_kind == _Kind.weekly)
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                    FilterChip(
                      label: Text(weekdayName(d)),
                      selected: _weekdays.contains(d),
                      onSelected: (on) => setState(() {
                        _weekdays = on
                            ? {..._weekdays, d}
                            : ({..._weekdays}..remove(d));
                      }),
                    ),
                ],
              ),
            if (_kind == _Kind.everyNDays)
              Row(
                children: [
                  IconButton(
                    tooltip: 'Fewer days',
                    onPressed: _n > 1 ? () => setState(() => _n--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('Every $_n days'),
                  IconButton(
                    tooltip: 'More days',
                    onPressed: () => setState(() => _n++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            AppSpacing.gapMd,
            FilledButton(
              onPressed: _kind == _Kind.weekly && _weekdays.isEmpty
                  ? null
                  : () => Navigator.pop(context, (_rule,)),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
