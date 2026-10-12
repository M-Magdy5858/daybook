import 'package:daybook/core/error/failures.dart';
import 'package:daybook/features/habits/domain/entities/habit.dart';
import 'package:equatable/equatable.dart';

/// A habit plus everything the screens show about it, worked out once.
class HabitView extends Equatable {
  const HabitView({
    required this.habit,
    required this.currentStreak,
    required this.bestStreak,
    required this.doneToday,
    required this.scheduledToday,
    required this.weekDone,
    required this.weekScheduled,
    required this.monthRate,
  });

  final Habit habit;
  final int currentStreak;
  final int bestStreak;
  final bool doneToday;
  final bool scheduledToday;

  /// Done and scheduled days this week (Monday to Sunday), for the ring.
  final int weekDone;
  final int weekScheduled;

  /// Completion rate over the last 30 days, 0.0 to 1.0.
  final double monthRate;

  double get weekProgress => weekScheduled == 0 ? 0 : weekDone / weekScheduled;

  @override
  List<Object?> get props => [
    habit,
    currentStreak,
    bestStreak,
    doneToday,
    scheduledToday,
    weekDone,
    weekScheduled,
    monthRate,
  ];
}

enum HabitsStatus { loading, ready }

class HabitsState extends Equatable {
  const HabitsState({
    this.status = HabitsStatus.loading,
    this.habits = const [],
    this.failure,
  });

  final HabitsStatus status;
  final List<HabitView> habits;

  /// The latest error to show once. Cleared by the next [copyWith].
  final Failure? failure;

  HabitView? byId(String id) =>
      habits.where((h) => h.habit.id == id).firstOrNull;

  HabitsState copyWith({
    HabitsStatus? status,
    List<HabitView>? habits,
    Failure? failure,
  }) => HabitsState(
    status: status ?? this.status,
    habits: habits ?? this.habits,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, habits, failure];
}
