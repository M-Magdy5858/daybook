import 'dart:async';

import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/habits/domain/entities/habit.dart';
import 'package:daybook/features/habits/domain/repositories/habit_repository.dart';
import 'package:daybook/features/habits/domain/services/habit_stats.dart';
import 'package:daybook/features/habits/presentation/cubit/habits_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

Habit _habit(List<DateTime> done, {Set<int> weekdays = Habit.everyDay}) =>
    Habit(
      id: 'h',
      name: 'Read',
      createdAt: DateTime(2026, 9, 1),
      weekdays: weekdays,
      completions: done.toSet(),
    );

class _MemoryHabits implements HabitRepository {
  _MemoryHabits(Habit habit) : _habit = habit;
  Habit _habit;
  final _changes = StreamController<List<Habit>>.broadcast();

  @override
  Stream<List<Habit>> watchHabits() async* {
    yield [_habit];
    yield* _changes.stream;
  }

  @override
  Future<Result<void>> save(Habit habit) async {
    _changes.add([_habit = habit]);
    return const Success(null);
  }

  @override
  Future<Result<void>> delete(String id) async => const Success(null);
}

void main() {
  // Thursday 2026-10-01.
  final today = DateTime(2026, 10, 1);

  group('HabitStats.currentStreak', () {
    test('a missed scheduled day breaks the streak', () {
      final h = _habit([DateTime(2026, 10, 1), DateTime(2026, 9, 29)]);
      expect(HabitStats.currentStreak(h, today), 1); // Sep 30 missed
    });

    test('a missed unscheduled day does not', () {
      // Mon/Wed/Fri only: Tue Sep 29 isn't scheduled.
      final h = _habit(
        [DateTime(2026, 9, 28), DateTime(2026, 9, 30)],
        weekdays: {DateTime.monday, DateTime.wednesday, DateTime.friday},
      );
      expect(HabitStats.currentStreak(h, today), 2);
    });

    test('today not done yet keeps yesterday\'s streak, across a month', () {
      final h = _habit([DateTime(2026, 9, 29), DateTime(2026, 9, 30)]);
      expect(HabitStats.currentStreak(h, today), 2);
      expect(HabitStats.bestStreak(h, today), 2);
    });
  });

  test('toggleToday updates the streak', () async {
    final cubit = HabitsCubit(
      _MemoryHabits(_habit([DateTime(2026, 9, 30)])),
      clock: () => today,
    )..load();
    addTearDown(cubit.close);
    await pumpEventQueue();
    expect(cubit.state.habits.single.currentStreak, 1);

    await cubit.toggleToday('h');
    await pumpEventQueue();
    expect(cubit.state.habits.single.currentStreak, 2);
    expect(cubit.state.habits.single.doneToday, isTrue);
  });
}
