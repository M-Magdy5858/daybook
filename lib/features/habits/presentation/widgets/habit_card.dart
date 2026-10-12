import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/habits/presentation/cubit/habits_cubit.dart';
import 'package:daybook/features/habits/presentation/cubit/habits_state.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:daybook/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Name, streak, the last 7 days, and a button to tick today.
class HabitCard extends StatelessWidget {
  const HabitCard({super.key, required this.view, required this.today});

  final HabitView view;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final habit = view.habit;
    final color = Color(habit.colorValue);
    final streak = view.currentStreak;

    return AppCard(
      onTap: () => context.push(Routes.habitDetail(habit.id)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.name, style: context.text.titleMedium),
                AppSpacing.gapXs,
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 18,
                      color: streak > 0
                          ? Colors.deepOrange
                          : context.colors.outline,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      streak == 1 ? '1 day streak' : '$streak day streak',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
                AppSpacing.gapSm,
                _LastSevenDays(view: view, today: today, color: color),
              ],
            ),
          ),
          AppSpacing.gapSm,
          _CheckButton(view: view, color: color),
        ],
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.view, required this.color});

  final HabitView view;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final done = view.doneToday;
    return Semantics(
      button: true,
      toggled: done,
      label: done
          ? '${view.habit.name}: done today'
          : '${view.habit.name}: mark done today',
      excludeSemantics: true,
      child: IconButton.filled(
        iconSize: 28,
        style: IconButton.styleFrom(
          backgroundColor: done
              ? color
              : context.colors.surfaceContainerHighest,
          foregroundColor: done
              ? Colors.white
              : context.colors.onSurfaceVariant,
          minimumSize: const Size.square(52),
        ),
        onPressed: () => context.read<HabitsCubit>().toggleToday(view.habit.id),
        icon: Icon(done ? Icons.check : Icons.check_outlined),
      ),
    );
  }
}

/// Seven small circles, oldest first: filled if done, outlined if scheduled
/// but missed, faint if it wasn't scheduled.
class _LastSevenDays extends StatelessWidget {
  const _LastSevenDays({
    required this.view,
    required this.today,
    required this.color,
  });

  final HabitView view;
  final DateTime today;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l = MaterialLocalizations.of(context);
    final habit = view.habit;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 6; i >= 0; i--)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: Builder(
                builder: (context) {
                  final day = today.addDays(-i);
                  final done = habit.isDoneOn(day);
                  final scheduled = habit.isScheduledOn(day);
                  return Column(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? color : null,
                          border: done
                              ? null
                              : Border.all(
                                  color: scheduled
                                      ? context.colors.outline
                                      : context.colors.outlineVariant,
                                ),
                        ),
                      ),
                      Text(
                        l.narrowWeekdays[day.weekday % 7],
                        style: context.text.labelSmall,
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
