import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/core/utils/id.dart';
import 'package:daybook/features/tasks/domain/entities/priority.dart';
import 'package:daybook/features/tasks/domain/entities/subtask.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/domain/services/task_validator.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_event.dart';
import 'package:daybook/features/tasks/presentation/widgets/recurrence_picker.dart';
import 'package:daybook/features/tasks/presentation/widgets/task_labels.dart';
import 'package:daybook/shared/models/recurrence_rule.dart';
import 'package:daybook/shared/widgets/app_button.dart';
import 'package:daybook/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Creates a task, or edits the one with [id].
class TaskFormPage extends StatefulWidget {
  const TaskFormPage({super.key, this.id});

  final String? id;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final Task? _existing = widget.id == null
      ? null
      : context.read<TasksBloc>().state.byId(widget.id!);

  late final _title = TextEditingController(text: _existing?.title);
  late final _notes = TextEditingController(text: _existing?.notes);
  final _newSubtask = TextEditingController();

  late Priority _priority = _existing?.priority ?? Priority.medium;
  late DateTime? _due = _existing?.dueDate;
  late RecurrenceRule? _recurrence = _existing?.recurrence;
  late List<Subtask> _subtasks = [...?_existing?.subtasks];

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _newSubtask.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due ?? DateTime(0, 1, 1, 9)),
    );
    if (time == null) return;
    setState(
      () => _due = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _pickRecurrence() async {
    final picked = await showRecurrencePicker(
      context,
      initial: _recurrence,
      anchor: _due ?? DateTime.now(),
    );
    if (picked != null) setState(() => _recurrence = picked.$1);
  }

  void _addSubtask() {
    final title = _newSubtask.text.trim();
    if (title.isEmpty) return;
    setState(
      () => _subtasks = [..._subtasks, Subtask(id: newId(), title: title)],
    );
    _newSubtask.clear();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final base =
        _existing ??
        Task(
          id: newId(),
          title: '',
          createdAt: DateTime.now(),
          // New tasks go to the top of "My order".
          position: -DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );
    final task = base.copyWith(
      title: _title.text,
      notes: _notes.text.trim(),
      priority: _priority,
      dueDate: _due,
      clearDueDate: _due == null,
      recurrence: _recurrence,
      clearRecurrence: _recurrence == null,
      subtasks: _subtasks,
    );
    context.read<TasksBloc>().add(TaskSaved(task));
    context.pop();
  }

  String? _validateTitle(String? v) {
    final title = (v ?? '').trim();
    if (title.isEmpty) return 'Required';
    if (title.length > TaskValidator.maxTitleLength) {
      return 'At most ${TaskValidator.maxTitleLength} characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final due = _due;
    final rule = _recurrence;
    return Scaffold(
      appBar: AppBar(title: Text(_existing == null ? 'New task' : 'Edit task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            AppTextField(
              label: 'Title',
              controller: _title,
              validator: _validateTitle,
              textInputAction: TextInputAction.next,
            ),
            AppSpacing.gapMd,
            AppTextField(label: 'Notes', controller: _notes, maxLines: 4),
            AppSpacing.gapMd,
            SegmentedButton<Priority>(
              segments: [
                for (final p in Priority.values)
                  ButtonSegment(value: p, label: Text(priorityLabel(p))),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            AppSpacing.gapSm,
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(
                due == null ? 'No due date' : formatDue(context, due),
              ),
              onTap: _pickDue,
              trailing: due == null
                  ? null
                  : IconButton(
                      tooltip: 'Clear due date',
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _due = null),
                    ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.repeat),
              title: Text(
                rule == null ? "Doesn't repeat" : describeRecurrence(rule),
              ),
              onTap: _pickRecurrence,
            ),
            AppSpacing.gapMd,
            Text('Subtasks', style: Theme.of(context).textTheme.titleMedium),
            for (final s in _subtasks)
              ListTile(
                key: ValueKey(s.id),
                contentPadding: EdgeInsets.zero,
                title: Text(s.title),
                trailing: IconButton(
                  tooltip: 'Remove subtask',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(
                    () => _subtasks = [
                      for (final x in _subtasks)
                        if (x.id != s.id) x,
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Add a subtask',
                    controller: _newSubtask,
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                IconButton(
                  tooltip: 'Add subtask',
                  icon: const Icon(Icons.add),
                  onPressed: _addSubtask,
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
