import 'package:daybook/core/notifications/notification_service.dart';
import 'package:daybook/core/theme/app_colors.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/core/utils/id.dart';
import 'package:daybook/features/habits/domain/entities/habit.dart';
import 'package:daybook/features/habits/presentation/cubit/habits_cubit.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/widgets/app_button.dart';
import 'package:daybook/shared/widgets/app_text_field.dart';
import 'package:daybook/shared/widgets/recurrence_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Creates a habit, or edits the one with [id].
class HabitFormPage extends StatefulWidget {
  const HabitFormPage({super.key, this.id});

  final String? id;

  @override
  State<HabitFormPage> createState() => _HabitFormPageState();
}

class _HabitFormPageState extends State<HabitFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final Habit? _existing = widget.id == null
      ? null
      : context.read<HabitsCubit>().state.byId(widget.id!)?.habit;

  late final _name = TextEditingController(text: _existing?.name);
  late int _color = _existing?.colorValue ?? AppColors.chart[2].toARGB32();
  late Set<int> _weekdays = {...(_existing?.weekdays ?? Habit.everyDay)};
  late bool _everyDay = _weekdays.length == 7;
  late TimeOfDay? _reminder = switch (_existing?.reminderMinutes) {
    null => null,
    final m => TimeOfDay(hour: m ~/ 60, minute: m % 60),
  };

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminder ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() => _reminder = picked);
    // The moment a reminder makes sense, so the prompt explains itself.
    context.read<NotificationService>().requestPermission();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final weekdays = _everyDay ? Habit.everyDay : _weekdays;
    final base =
        _existing ?? Habit(id: newId(), name: '', createdAt: DateTime.now());
    final reminder = _reminder;
    context.read<HabitsCubit>().save(
      base.copyWith(
        name: _name.text.trim(),
        colorValue: _color,
        weekdays: weekdays,
        reminderMinutes: reminder == null
            ? null
            : reminder.hour * 60 + reminder.minute,
        clearReminder: reminder == null,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final reminder = _reminder;
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'New habit' : 'Edit habit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            AppTextField(
              label: 'Name',
              hint: 'e.g. Read 20 pages',
              controller: _name,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            AppSpacing.gapLg,
            Text('How often', style: context.text.titleSmall),
            AppSpacing.gapSm,
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Every day')),
                ButtonSegment(value: false, label: Text('Some days')),
              ],
              selected: {_everyDay},
              onSelectionChanged: (s) => setState(() => _everyDay = s.first),
            ),
            if (!_everyDay) ...[
              AppSpacing.gapSm,
              FormField<Set<int>>(
                validator: (_) =>
                    _weekdays.isEmpty ? 'Pick at least one day' : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    if (field.errorText != null)
                      Text(
                        field.errorText!,
                        style: TextStyle(color: context.colors.error),
                      ),
                  ],
                ),
              ),
            ],
            AppSpacing.gapLg,
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Daily reminder'),
              subtitle: reminder == null
                  ? null
                  : Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatTimeOfDay(reminder),
                    ),
              value: reminder != null,
              onChanged: (on) =>
                  on ? _pickReminder() : setState(() => _reminder = null),
            ),
            if (reminder != null)
              TextButton(
                onPressed: _pickReminder,
                child: const Text('Change time'),
              ),
            AppSpacing.gapMd,
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
