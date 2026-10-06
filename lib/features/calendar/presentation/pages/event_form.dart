import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/core/theme/app_colors.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/core/utils/id.dart';
import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/features/calendar/presentation/cubit/calendar_cubit.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:daybook/shared/models/recurrence_rule.dart';
import 'package:daybook/shared/widgets/app_button.dart';
import 'package:daybook/shared/widgets/app_text_field.dart';
import 'package:daybook/shared/widgets/recurrence_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Creates an event (optionally scheduled from a task), or edits the one
/// with [id].
class EventFormPage extends StatefulWidget {
  const EventFormPage({
    super.key,
    this.id,
    this.initialDate,
    this.taskId,
    this.taskTitle,
  });

  final String? id;
  final DateTime? initialDate;
  final String? taskId;
  final String? taskTitle;

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final Event? _existing = widget.id == null
      ? null
      : context
            .read<CalendarCubit>()
            .state
            .events
            .where((e) => e.id == widget.id)
            .firstOrNull;

  late final _title = TextEditingController(
    text: _existing?.title ?? widget.taskTitle,
  );
  late bool _allDay = _existing?.allDay ?? false;
  late DateTime _start = _existing?.start ?? _defaultStart();
  late DateTime _end = _existing?.end ?? _start.add(const Duration(hours: 1));
  late int _color = _existing?.colorValue ?? AppColors.chart[1].toARGB32();
  late RecurrenceRule? _recurrence = _existing?.recurrence;
  late final String? _taskId = _existing?.linkedTaskId ?? widget.taskId;
  String? _endError;

  DateTime _defaultStart() {
    final now = DateTime.now();
    final day = widget.initialDate ?? now;
    // Today: the next full hour. Another day: 9:00.
    return day.isSameDay(now)
        ? DateTime(now.year, now.month, now.day, now.hour + 1)
        : DateTime(day.year, day.month, day.day, 9);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 5),
      lastDate: DateTime(initial.year + 5),
    );
    if (date == null || !mounted) return null;
    if (_allDay) return date;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickStart() async {
    final picked = await _pick(_start);
    if (picked == null) return;
    // Keep the same length when the start moves.
    setState(() {
      _end = picked.add(_end.difference(_start));
      _start = picked;
    });
  }

  Future<void> _pickEnd() async {
    final picked = await _pick(_allDay ? _end.addDays(-1) : _end);
    if (picked == null) return;
    setState(() => _end = _allDay ? picked.startOfDay.addDays(1) : picked);
  }

  void _setAllDay(bool allDay) => setState(() {
    _allDay = allDay;
    if (allDay) {
      // All-day events run from midnight to the midnight after the last day.
      final lastDay = _end.isAfter(_start) ? _end.addDays(-1) : _start;
      _start = _start.startOfDay;
      _end = (lastDay.isBefore(_start) ? _start : lastDay.startOfDay).addDays(
        1,
      );
    } else {
      _start = DateTime(_start.year, _start.month, _start.day, 9);
      _end = _start.add(const Duration(hours: 1));
    }
  });

  Future<void> _pickRecurrence() async {
    final picked = await showRecurrencePicker(
      context,
      initial: _recurrence,
      anchor: _start,
    );
    if (picked != null) setState(() => _recurrence = picked.$1);
  }

  void _save() {
    setState(
      () => _endError = _end.isAfter(_start) ? null : 'Must be after the start',
    );
    if (!_formKey.currentState!.validate() || _endError != null) return;
    final base =
        _existing ??
        Event(
          id: newId(),
          title: '',
          start: _start,
          end: _end,
          createdAt: DateTime.now(),
          linkedTaskId: _taskId,
        );
    context.read<CalendarCubit>().saveEvent(
      base.copyWith(
        title: _title.text.trim(),
        start: _start,
        end: _end,
        allDay: _allDay,
        colorValue: _color,
        recurrence: _recurrence,
        clearRecurrence: _recurrence == null,
      ),
    );
    context.pop();
  }

  void _delete() {
    context.read<CalendarCubit>().deleteEvent(_existing!.id);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = MaterialLocalizations.of(context);
    String format(DateTime d) => _allDay
        ? l.formatMediumDate(d)
        : '${l.formatMediumDate(d)} · '
              '${l.formatTimeOfDay(TimeOfDay.fromDateTime(d))}';
    final rule = _recurrence;

    if (widget.id != null && _existing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Event not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'New event' : 'Edit event'),
        actions: [
          if (_existing != null)
            IconButton(
              tooltip: 'Delete event',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            AppTextField(
              label: 'Title',
              controller: _title,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            if (_taskId != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.task_alt),
                title: const Text('Scheduled from a task'),
                trailing: const Icon(Icons.chevron_right),
                // `go`, not `push`: the task lives in another tab.
                onTap: () => context.go(Routes.taskDetail(_taskId)),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('All day'),
              value: _allDay,
              onChanged: _setAllDay,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.play_arrow_outlined),
              title: const Text('Starts'),
              subtitle: Text(format(_start)),
              onTap: _pickStart,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.stop_outlined),
              title: const Text('Ends'),
              subtitle: Text(
                _endError ?? format(_allDay ? _end.addDays(-1) : _end),
                style: _endError == null
                    ? null
                    : TextStyle(color: context.colors.error),
              ),
              onTap: _pickEnd,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.repeat),
              title: Text(
                rule == null ? "Doesn't repeat" : describeRecurrence(rule),
              ),
              onTap: _pickRecurrence,
            ),
            AppSpacing.gapSm,
            Text('Color', style: context.text.titleSmall),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final c in AppColors.chart)
                  Semantics(
                    button: true,
                    selected: c.toARGB32() == _color,
                    label: 'Color',
                    child: InkResponse(
                      onTap: () => setState(() => _color = c.toARGB32()),
                      radius: 24,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: c,
                        child: c.toARGB32() == _color
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            AppSpacing.gapLg,
            AppButton(label: 'Save', expand: true, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
