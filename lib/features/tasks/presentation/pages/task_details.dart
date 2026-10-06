import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_event.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_state.dart';
import 'package:daybook/features/tasks/presentation/widgets/task_labels.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/widgets/recurrence_picker.dart';
import 'package:daybook/shared/widgets/app_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TaskDetailsPage extends StatelessWidget {
  const TaskDetailsPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final (status, task) = context.select(
      (TasksBloc b) => (b.state.status, b.state.byId(id)),
    );

    if (task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: status == TasksStatus.success
            ? const AppEmptyState(
                title: 'Task not found',
                message: 'It may have been deleted.',
              )
            : const AppLoadingState(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Schedule on calendar',
            icon: const Icon(Icons.event_available_outlined),
            onPressed: () => context.push(
              Routes.eventNewFor(taskId: task.id, title: task.title),
            ),
          ),
          IconButton(
            tooltip: 'Edit task',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.taskEdit(id)),
          ),
          IconButton(
            tooltip: 'Delete task',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, task),
          ),
        ],
      ),
      body: _Details(task: task),
    );
  }

  void _delete(BuildContext context, Task task) {
    final bloc = context.read<TasksBloc>()..add(TaskDeleted(task.id));
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Task deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => bloc.add(TaskRestored(task)),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TasksBloc>();
    final due = task.dueDate;
    final rule = task.recurrence;
    final (done, total) = task.progress;

    return ListView(
      padding: AppSpacing.page,
      children: [
        Hero(
          tag: 'task-${task.id}',
          child: Material(
            type: MaterialType.transparency,
            child: Text(task.title, style: context.text.headlineSmall),
          ),
        ),
        AppSpacing.gapSm,
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: task.isCompleted,
          title: Text(task.isCompleted ? 'Done' : 'Not done yet'),
          onChanged: (_) => bloc.add(TaskToggled(task.id)),
        ),
        _InfoRow(
          icon: Icons.flag_outlined,
          text: '${priorityLabel(task.priority)} priority',
          color: priorityColor(task.priority),
        ),
        if (due != null)
          _InfoRow(
            icon: Icons.event_outlined,
            text: formatDue(context, due),
            color: task.isOverdue(DateTime.now()) ? context.colors.error : null,
          ),
        if (rule != null)
          _InfoRow(icon: Icons.repeat, text: describeRecurrence(rule)),
        if (task.notes.isNotEmpty) ...[AppSpacing.gapMd, Text(task.notes)],
        if (total > 0) ...[
          AppSpacing.gapLg,
          Text('Subtasks  $done/$total', style: context.text.titleMedium),
          for (final s in task.subtasks)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: s.done,
              title: Text(s.title),
              onChanged: (v) => bloc.add(
                TaskSaved(
                  task.copyWith(
                    subtasks: [
                      for (final x in task.subtasks)
                        x.id == s.id ? x.copyWith(done: v) : x,
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        Icon(icon, size: 20, color: color),
        AppSpacing.gapSm,
        Expanded(
          child: Text(text, style: TextStyle(color: color)),
        ),
      ],
    ),
  );
}
