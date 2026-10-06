import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_event.dart';
import 'package:daybook/features/tasks/presentation/widgets/task_labels.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// One row in the task list. Swipe right to complete, left to delete.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.now});

  final Task task;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TasksBloc>();
    return Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      background: _SwipeBackground(
        color: context.colors.primary,
        icon: task.isCompleted ? Icons.undo : Icons.check,
        alignment: AlignmentDirectional.centerStart,
      ),
      secondaryBackground: _SwipeBackground(
        color: context.colors.error,
        icon: Icons.delete,
        alignment: AlignmentDirectional.centerEnd,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          bloc.add(TaskToggled(task.id));
          return false; // the row stays; it just changes state
        }
        return true;
      },
      onDismissed: (_) {
        bloc.add(TaskDeleted(task.id));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Task deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => bloc.add(TaskRestored(task)),
              ),
            ),
          );
      },
      child: _CardBody(task: task, now: now),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.task, required this.now});

  final Task task;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final (done, total) = task.progress;
    final overdue = task.isOverdue(now);
    final due = task.dueDate;

    return ListTile(
      onTap: () => context.push(Routes.taskDetail(task.id)),
      leading: Checkbox(
        value: task.isCompleted,
        onChanged: (_) => context.read<TasksBloc>().add(TaskToggled(task.id)),
      ),
      title: Hero(
        tag: 'task-${task.id}',
        child: Material(
          type: MaterialType.transparency,
          child: Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? context.colors.outline : null,
            ),
          ),
        ),
      ),
      subtitle: (due == null && total == 0 && task.recurrence == null)
          ? null
          : Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (due != null)
                  Text(
                    formatDue(context, due),
                    style: TextStyle(
                      color: overdue ? context.colors.error : null,
                      fontWeight: overdue ? FontWeight.bold : null,
                    ),
                  ),
                if (task.recurrence != null) const Icon(Icons.repeat, size: 14),
                if (total > 0) Text('$done/$total'),
              ],
            ),
      trailing: Tooltip(
        message: '${priorityLabel(task.priority)} priority',
        child: CircleAvatar(
          radius: 6,
          backgroundColor: priorityColor(task.priority),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color,
    child: Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Icon(icon, color: context.colors.onPrimary),
      ),
    ),
  );
}
