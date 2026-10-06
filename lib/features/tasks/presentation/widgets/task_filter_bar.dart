import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/tasks/domain/services/task_query.dart';
import 'package:flutter/material.dart';

class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TaskFilter selected;
  final ValueChanged<TaskFilter> onChanged;

  static const _labels = {
    TaskFilter.all: 'All',
    TaskFilter.active: 'Active',
    TaskFilter.today: 'Today',
    TaskFilter.overdue: 'Overdue',
    TaskFilter.completed: 'Done',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          for (final MapEntry(key: filter, value: label) in _labels.entries)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(label),
                selected: filter == selected,
                onSelected: (_) => onChanged(filter),
              ),
            ),
        ],
      ),
    );
  }
}
