import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/habits/domain/entities/habit.dart';

abstract interface class HabitRepository {
  /// Every habit, re-emitted whenever any of them changes.
  Stream<List<Habit>> watchHabits();
  Future<Result<void>> save(Habit habit);
  Future<Result<void>> delete(String id);

  /// Fetch this collection's latest copies from the server, nothing else.
  Future<Result<void>> pull();
}
