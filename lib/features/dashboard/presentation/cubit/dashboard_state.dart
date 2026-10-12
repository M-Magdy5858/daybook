import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/features/expenses/domain/entities/expense_category.dart';
import 'package:daybook/features/habits/domain/entities/habit.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/shared/models/money.dart';
import 'package:daybook/shared/models/section_state.dart';
import 'package:equatable/equatable.dart';

/// The Dashboard's sections, so one can be retried by name.
enum DashboardPart { tasks, events, habits, spending }

/// Today's scheduled habits and how many are done.
class HabitsToday extends Equatable {
  const HabitsToday({required this.habits, required this.done});

  final List<Habit> habits;
  final int done;

  @override
  List<Object?> get props => [habits, done];
}

/// This month's spending against the total of every category budget.
class MonthSpending extends Equatable {
  const MonthSpending({required this.spent, this.budget, this.top = const []});

  final Money spent;

  /// Null when no category has a budget.
  final Money? budget;

  /// The biggest categories this month, largest first.
  final List<(ExpenseCategory, Money)> top;

  @override
  List<Object?> get props => [spent, budget, top];
}

/// No page-wide `isLoading`: every section loads, fails and retries alone.
class DashboardState extends Equatable {
  const DashboardState({
    this.todayTasks = const SectionLoading(),
    this.upcomingEvents = const SectionLoading(),
    this.habitsToday = const SectionLoading(),
    this.monthSpending = const SectionLoading(),
  });

  final SectionState<List<Task>> todayTasks;
  final SectionState<List<EventOccurrence>> upcomingEvents;
  final SectionState<HabitsToday> habitsToday;
  final SectionState<MonthSpending> monthSpending;

  DashboardState copyWith({
    SectionState<List<Task>>? todayTasks,
    SectionState<List<EventOccurrence>>? upcomingEvents,
    SectionState<HabitsToday>? habitsToday,
    SectionState<MonthSpending>? monthSpending,
  }) => DashboardState(
    todayTasks: todayTasks ?? this.todayTasks,
    upcomingEvents: upcomingEvents ?? this.upcomingEvents,
    habitsToday: habitsToday ?? this.habitsToday,
    monthSpending: monthSpending ?? this.monthSpending,
  );

  @override
  List<Object?> get props => [
    todayTasks,
    upcomingEvents,
    habitsToday,
    monthSpending,
  ];
}
