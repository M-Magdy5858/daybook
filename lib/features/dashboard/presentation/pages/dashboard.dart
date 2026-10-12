import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_state.dart';
import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:daybook/features/dashboard/presentation/widgets/dashboard_section.dart';
import 'package:daybook/features/dashboard/presentation/widgets/quick_actions.dart';
import 'package:daybook/features/expenses/presentation/widgets/budget_bar.dart';
import 'package:daybook/features/expenses/presentation/widgets/category_icon.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/models/section_state.dart';
import 'package:daybook/shared/widgets/progress_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// "Good morning" before noon, "Good afternoon" until 5 pm, then evening.
String greeting(DateTime now) => switch (now.hour) {
  < 12 => 'Good morning',
  < 17 => 'Good afternoon',
  _ => 'Good evening',
};

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final name = switch (context.select((AuthBloc b) => b.state)) {
      Authenticated(:final user) => ', ${user.name}',
      _ => '',
    };
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text('${greeting(now)}$name')),
      body: RefreshIndicator(
        onRefresh: cubit.load,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            Text(
              DateFormat.yMMMMEEEEd(
                Localizations.localeOf(context).toString(),
              ).format(now),
              style: context.text.titleMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapLg,
            const QuickActions(),
            AppSpacing.gapLg,
            // Each BlocSelector rebuilds only when its own section changes.
            BlocSelector<
              DashboardCubit,
              DashboardState,
              SectionState<List<Task>>
            >(
              selector: (s) => s.todayTasks,
              builder: (_, state) => DashboardSection(
                title: "Today's tasks",
                state: state,
                emptyText: 'Nothing due today',
                onRetry: () => cubit.retry(DashboardPart.tasks),
                onSeeAll: () => context.go(Routes.tasks),
                builder: (tasks) => Column(
                  children: [for (final t in tasks) _TaskRow(task: t)],
                ),
              ),
            ),
            AppSpacing.gapLg,
            BlocSelector<
              DashboardCubit,
              DashboardState,
              SectionState<List<EventOccurrence>>
            >(
              selector: (s) => s.upcomingEvents,
              builder: (_, state) => DashboardSection(
                title: 'Coming up',
                state: state,
                emptyText: 'No events this week',
                onRetry: () => cubit.retry(DashboardPart.events),
                onSeeAll: () => context.go(Routes.calendar),
                builder: (events) => Column(
                  children: [for (final o in events) _EventRow(occurrence: o)],
                ),
              ),
            ),
            AppSpacing.gapLg,
            BlocSelector<
              DashboardCubit,
              DashboardState,
              SectionState<HabitsToday>
            >(
              selector: (s) => s.habitsToday,
              builder: (_, state) => DashboardSection(
                title: 'Habits today',
                state: state,
                emptyText: 'No habits scheduled today',
                onRetry: () => cubit.retry(DashboardPart.habits),
                onSeeAll: () => context.go(Routes.habits),
                builder: (today) => _HabitsSummary(today: today),
              ),
            ),
            AppSpacing.gapLg,
            BlocSelector<
              DashboardCubit,
              DashboardState,
              SectionState<MonthSpending>
            >(
              selector: (s) => s.monthSpending,
              builder: (_, state) => DashboardSection(
                title: 'This month',
                state: state,
                emptyText: 'Nothing spent yet this month',
                onRetry: () => cubit.retry(DashboardPart.spending),
                onSeeAll: () => context.go(Routes.expenses),
                builder: (spending) => _SpendingSummary(spending: spending),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final Task task;

  Future<void> _toggle(BuildContext context) async {
    final result = await context.read<DashboardCubit>().toggleTask(task);
    if (result case Err(:final failure) when context.mounted) {
      context.showSnack(failure.message);
    }
  }

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Checkbox(
      value: task.isCompleted,
      onChanged: (_) => _toggle(context),
    ),
    title: Text(
      task.title,
      style: task.isCompleted
          ? TextStyle(
              decoration: TextDecoration.lineThrough,
              color: context.colors.onSurfaceVariant,
            )
          : null,
    ),
    subtitle: Text(TimeOfDay.fromDateTime(task.dueDate!).format(context)),
    onTap: () => context.go(Routes.taskDetail(task.id)),
  );
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.occurrence});

  final EventOccurrence occurrence;

  String _when(BuildContext context) {
    final start = occurrence.start;
    final now = DateTime.now();
    final day = DateUtils.dateOnly(start).difference(DateUtils.dateOnly(now));
    final dayLabel = switch (day.inDays) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => DateFormat.EEEE(
        Localizations.localeOf(context).toString(),
      ).format(start),
    };
    if (occurrence.event.allDay) return '$dayLabel · All day';
    final from = TimeOfDay.fromDateTime(start).format(context);
    final to = TimeOfDay.fromDateTime(occurrence.end).format(context);
    return '$dayLabel · $from – $to';
  }

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      radius: 6,
      backgroundColor: Color(occurrence.event.colorValue),
    ),
    minLeadingWidth: 12,
    title: Text(occurrence.event.title),
    subtitle: Text(_when(context)),
    onTap: () => context.go(Routes.eventDetail(occurrence.event.id)),
  );
}

class _HabitsSummary extends StatelessWidget {
  const _HabitsSummary({required this.today});

  final HabitsToday today;

  @override
  Widget build(BuildContext context) {
    final total = today.habits.length;
    final now = DateTime.now();
    return Row(
      children: [
        ProgressRing(
          value: today.done / total,
          size: 72,
          strokeWidth: 8,
          child: Text('${today.done}/$total', style: context.text.titleMedium),
        ),
        AppSpacing.gapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final h in today.habits)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        h.isDoneOn(now)
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: Color(h.colorValue),
                      ),
                      AppSpacing.gapSm,
                      Expanded(
                        child: Text(h.name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpendingSummary extends StatelessWidget {
  const _SpendingSummary({required this.spending});

  final MonthSpending spending;

  @override
  Widget build(BuildContext context) {
    final budget = spending.budget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.formatMoney(spending.spent),
          style: context.text.headlineSmall,
        ),
        if (budget != null) ...[
          Text('spent of ${context.formatMoney(budget)} budgeted'),
          AppSpacing.gapSm,
          BudgetBar(use: spending.spent.ratioOf(budget)),
        ] else
          const Text('spent'),
        AppSpacing.gapSm,
        for (final (category, amount) in spending.top)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: CategoryAvatar(category: category, radius: 14),
            title: Text(category.name),
            trailing: Text(context.formatMoney(amount)),
          ),
      ],
    );
  }
}
