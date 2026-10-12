import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/habits/presentation/cubit/habits_cubit.dart';
import 'package:daybook/features/habits/presentation/cubit/habits_state.dart';
import 'package:daybook/features/habits/presentation/widgets/habit_card.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:daybook/shared/widgets/app_states.dart';
import 'package:daybook/shared/widgets/progress_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New habit',
        onPressed: () => context.push(Routes.habitNew),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<HabitsCubit, HabitsState>(
        listenWhen: (prev, next) =>
            next.failure != null && prev.failure != next.failure,
        listener: (context, state) => context.showSnack(state.failure!.message),
        builder: (context, state) {
          if (state.status == HabitsStatus.loading) {
            return const AppLoadingState();
          }
          if (state.habits.isEmpty) {
            return const AppEmptyState(
              title: 'No habits yet',
              message: 'Tap + to start one. Small and daily works best.',
              icon: Icons.local_fire_department_outlined,
            );
          }
          final today = DateTime.now().startOfDay;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              96, // room for the button
            ),
            children: [
              _TodaySummary(habits: state.habits),
              AppSpacing.gapMd,
              for (final view in state.habits) ...[
                HabitCard(
                  key: ValueKey(view.habit.id),
                  view: view,
                  today: today,
                ),
                AppSpacing.gapSm,
              ],
            ],
          );
        },
      ),
    );
  }
}

/// "2 of 4 done today", with a ring.
class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.habits});

  final List<HabitView> habits;

  @override
  Widget build(BuildContext context) {
    final due = habits.where((h) => h.scheduledToday).toList();
    final done = due.where((h) => h.doneToday).length;
    final message = due.isEmpty
        ? 'Nothing scheduled today. Enjoy the rest!'
        : done == due.length
        ? 'All done for today. Nice work!'
        : '${due.length - done} to go today';

    return Semantics(
      label: 'Today: $done of ${due.length} habits done',
      excludeSemantics: true,
      child: Row(
        children: [
          ProgressRing(
            value: due.isEmpty ? 0 : done / due.length,
            size: 72,
            strokeWidth: 8,
            child: Text('$done/${due.length}', style: context.text.titleMedium),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today', style: context.text.titleLarge),
                Text(message, style: context.text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
