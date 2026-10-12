import 'dart:async';

import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/habits/domain/entities/habit.dart';
import 'package:daybook/features/habits/domain/repositories/habit_repository.dart';
import 'package:daybook/features/habits/domain/services/habit_stats.dart';
import 'package:daybook/features/habits/presentation/cubit/habits_state.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HabitsCubit extends Cubit<HabitsState> {
  HabitsCubit(this._repository, {DateTime Function() clock = DateTime.now})
    : _now = clock,
      super(const HabitsState());

  final HabitRepository _repository;
  final DateTime Function() _now;
  StreamSubscription<List<Habit>>? _sub;
  List<Habit> _habits = const [];

  /// Listen to the database; every change recomputes the stats.
  void load() {
    _sub ??= _repository.watchHabits().listen((habits) {
      _habits = habits;
      _emitViews();
    });
  }

  Future<void> save(Habit habit) =>
      _write(_repository.save(habit.copyWith(updatedAt: _now())));

  Future<void> delete(String id) => _write(_repository.delete(id));

  Future<void> toggleToday(String id) => toggleDay(id, _now());

  /// Mark [day] done, or not done if it already was. Future days are ignored.
  Future<void> toggleDay(String id, DateTime day) async {
    final date = day.startOfDay;
    if (date.isAfter(_now().startOfDay)) return;
    final habit = _habits.where((h) => h.id == id).firstOrNull;
    if (habit == null) return;
    final completions = habit.isDoneOn(date)
        ? ({...habit.completions}..remove(date))
        : {...habit.completions, date};
    // Show it at once; the database confirms a moment later.
    _habits = [
      for (final h in _habits)
        h.id == id ? h.copyWith(completions: completions) : h,
    ];
    _emitViews();
    await save(habit.copyWith(completions: completions));
  }

  void _emitViews() {
    final today = _now().startOfDay;
    final monday = today.startOfWeek;
    final sorted = [..._habits]..sort((a, b) => a.name.compareTo(b.name));
    emit(
      state.copyWith(
        status: HabitsStatus.ready,
        habits: [for (final h in sorted) _view(h, today, monday)],
      ),
    );
  }

  HabitView _view(Habit h, DateTime today, DateTime monday) {
    var weekDone = 0;
    var weekScheduled = 0;
    for (var i = 0; i < 7; i++) {
      final day = monday.addDays(i);
      if (!h.isScheduledOn(day)) continue;
      weekScheduled++;
      if (h.isDoneOn(day)) weekDone++;
    }
    return HabitView(
      habit: h,
      currentStreak: HabitStats.currentStreak(h, today),
      bestStreak: HabitStats.bestStreak(h, today),
      doneToday: h.isDoneOn(today),
      scheduledToday: h.isScheduledOn(today),
      weekDone: weekDone,
      weekScheduled: weekScheduled,
      monthRate: HabitStats.completionRate(h, today.addDays(-29), today),
    );
  }

  Future<void> _write(Future<Result<void>> op) async {
    if (await op case Err(:final failure)) {
      emit(state.copyWith(failure: failure));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
