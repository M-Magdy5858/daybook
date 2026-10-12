import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/habits/presentation/cubit/habits_cubit.dart';
import 'package:daybook/features/habits/presentation/cubit/habits_state.dart';
import 'package:daybook/features/habits/presentation/widgets/habit_heatmap.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:daybook/shared/widgets/app_card.dart';
import 'package:daybook/shared/widgets/app_states.dart';
import 'package:daybook/shared/widgets/progress_ring.dart';
import 'package:daybook/shared/widgets/recurrence_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HabitDetailsPage extends StatelessWidget {
  const HabitDetailsPage({super.key, required this.id});

  final String id;

  Future<void> _delete(BuildContext context, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$name"?'),
        content: const Text('Its history and streaks will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<HabitsCubit>().delete(id);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final (status, view) = context.select(
      (HabitsCubit c) => (c.state.status, c.state.byId(id)),
    );
    if (view == null) {
      return Scaffold(
        appBar: AppBar(),
        body: status == HabitsStatus.ready
            ? const AppEmptyState(title: 'Habit not found')
            : const AppLoadingState(),
      );
    }
    final habit = view.habit;
    final color = Color(habit.colorValue);
    final today = DateTime.now().startOfDay;
    final cubit = context.read<HabitsCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(
            tooltip: 'Edit habit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.habitEdit(id)),
          ),
          IconButton(
            tooltip: 'Delete habit',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, habit.name),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Center(
            child: Semantics(
              label:
                  'This week: ${view.weekDone} of ${view.weekScheduled} days done',
              excludeSemantics: true,
              child: ProgressRing(
                value: view.weekProgress,
                size: 160,
                strokeWidth: 14,
                color: color,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${view.weekDone}/${view.weekScheduled}',
                      style: context.text.headlineMedium,
                    ),
                    Text('this week', style: context.text.bodySmall),
                  ],
                ),
              ),
            ),
          ),
          AppSpacing.gapMd,
          Center(
            child: view.doneToday
                ? OutlinedButton.icon(
                    onPressed: () => cubit.toggleToday(id),
                    icon: const Icon(Icons.undo),
                    label: const Text('Done today · undo'),
                  )
                : FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: color),
                    onPressed: () => cubit.toggleToday(id),
                    icon: const Icon(Icons.check),
                    label: const Text('Mark today done'),
                  ),
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              _Stat(
                icon: Icons.local_fire_department,
                value: '${view.currentStreak}',
                label: 'Current streak',
              ),
              _Stat(
                icon: Icons.emoji_events_outlined,
                value: '${view.bestStreak}',
                label: 'Best streak',
              ),
              _Stat(
                icon: Icons.percent,
                value: '${(view.monthRate * 100).round()}%',
                label: 'Last 30 days',
              ),
            ],
          ),
          AppSpacing.gapLg,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Past year', style: context.text.titleMedium),
                Text(
                  'Tap a day to change it',
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                AppSpacing.gapMd,
                HabitHeatmap(
                  habit: habit,
                  today: today,
                  onToggle: (day) => cubit.toggleDay(id, day),
                ),
              ],
            ),
          ),
          AppSpacing.gapMd,
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_repeat),
            title: Text(
              habit.isEveryDay
                  ? 'Every day'
                  : (habit.weekdays.toList()..sort())
                        .map(weekdayName)
                        .join(', '),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_outlined),
            title: Text(
              habit.reminderMinutes == null
                  ? 'No reminder'
                  : 'Reminder at ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: habit.reminderMinutes! ~/ 60, minute: habit.reminderMinutes! % 60))}',
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MergeSemantics(
        child: Column(
          children: [
            Icon(icon, color: context.colors.primary),
            Text(value, style: context.text.titleLarge),
            Text(
              label,
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
