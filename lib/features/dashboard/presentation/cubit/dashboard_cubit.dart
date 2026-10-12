import 'dart:async';

import 'package:daybook/core/error/error_mapper.dart';
import 'package:daybook/core/error/failures.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/features/calendar/domain/repositories/event_repository.dart';
import 'package:daybook/features/calendar/domain/services/occurrence_expander.dart';
import 'package:daybook/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:daybook/features/expenses/domain/entities/expense_category.dart';
import 'package:daybook/features/expenses/domain/entities/transaction.dart';
import 'package:daybook/features/expenses/domain/repositories/expense_repository.dart';
import 'package:daybook/features/expenses/domain/services/expense_summary.dart';
import 'package:daybook/features/habits/domain/entities/habit.dart';
import 'package:daybook/features/habits/domain/repositories/habit_repository.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/domain/repositories/task_repository.dart';
import 'package:daybook/features/tasks/domain/usecases/complete_task.dart';
import 'package:daybook/shared/models/section_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'dashboard_state.dart';

/// The Dashboard has no data layer of its own: it reads the repositories the
/// other features already have. Each section asks the server for its own
/// collection, then follows the local data so it stays up to date.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required this._tasks,
    required this._events,
    required this._habits,
    required this._expenses,
    required this._completeTask,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       super(const DashboardState());

  final TaskRepository _tasks;
  final EventRepository _events;
  final HabitRepository _habits;
  final ExpenseRepository _expenses;
  final CompleteTask _completeTask;
  final DateTime Function() _now;

  final _subs = <DashboardPart, StreamSubscription<void>>{};

  /// Counts each section's loads, so a slow older load that finishes after a
  /// newer one (or after close) is ignored.
  final _loads = <DashboardPart, int>{};
  var _closing = false;

  static const maxTasks = 5;
  static const maxEvents = 3;

  /// Starts every section at once, without awaiting one before the next, so
  /// the page takes as long as the slowest section, not all of them added up.
  /// The returned future (for pull-to-refresh) ends when all have finished.
  Future<void> load() =>
      Future.wait([for (final part in DashboardPart.values) retry(part)]);

  /// Reloads only [part]; the other sections aren't touched.
  Future<void> retry(DashboardPart part) => switch (part) {
    DashboardPart.tasks => _load(
      part,
      pull: _tasks.pull,
      watch: () => _tasks.watchTasks().map(_todayTasks),
      put: (s) => state.copyWith(todayTasks: s),
    ),
    DashboardPart.events => _load(
      part,
      pull: _events.pull,
      watch: () => _events.watchEvents().map(_upcoming),
      put: (s) => state.copyWith(upcomingEvents: s),
    ),
    DashboardPart.habits => _load(
      part,
      pull: _habits.pull,
      watch: () => _habits.watchHabits().map(_habitsToday),
      put: (s) => state.copyWith(habitsToday: s),
    ),
    DashboardPart.spending => _load(
      part,
      pull: _expenses.pull,
      watch: () => _expenses.watchTransactions().asyncMap(
        (txs) async => _spending(txs, await _expenses.watchCategories().first),
      ),
      put: (s) => state.copyWith(monthSpending: s),
    ),
  };

  /// Tick a task done (or undo it) right on the Dashboard.
  Future<Result<void>> toggleTask(Task task) =>
      _completeTask(task, now: _now());

  /// Loading → ask the server → then follow the local data, where null means
  /// there's nothing to show.
  Future<void> _load<T>(
    DashboardPart part, {
    required Future<Result<void>> Function() pull,
    required Stream<T?> Function() watch,
    required DashboardState Function(SectionState<T>) put,
  }) async {
    final load = _loads[part] = (_loads[part] ?? 0) + 1;
    await _subs.remove(part)?.cancel();
    if (_closing) return;
    emit(put(SectionLoading<T>()));

    final pulled = await pull();
    if (_closing || _loads[part] != load) return;
    // Being offline is normal here: show what's saved on the phone. Any
    // other failure means the server said no, so offer Retry.
    if (pulled case Err(:final failure) when failure is! NetworkFailure) {
      emit(put(SectionError<T>(failure)));
      return;
    }

    final firstValue = Completer<void>();
    void settle(SectionState<T> section) {
      emit(put(section));
      if (!firstValue.isCompleted) firstValue.complete();
    }

    _subs[part] = watch().listen(
      (data) => settle(data == null ? SectionEmpty<T>() : SectionData(data)),
      onError: (Object e) => settle(SectionError<T>(ErrorMapper.toFailure(e))),
    );
    return firstValue.future;
  }

  /// Due today, not-done first, at most [maxTasks]. Done ones stay so a tick
  /// can be undone.
  List<Task>? _todayTasks(List<Task> all) {
    final now = _now();
    final today =
        [
          for (final t in all)
            if (t.dueDate case final due?
                when due.year == now.year &&
                    due.month == now.month &&
                    due.day == now.day)
              t,
        ]..sort((a, b) {
          if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
    return today.isEmpty ? null : today.take(maxTasks).toList();
  }

  /// The next [maxEvents] occurrences in the coming week, including one
  /// that's already started.
  List<EventOccurrence>? _upcoming(List<Event> events) {
    final now = _now();
    final next = const OccurrenceExpander()
        .expand(events, now, now.add(const Duration(days: 7)))
        .take(maxEvents)
        .toList();
    return next.isEmpty ? null : next;
  }

  HabitsToday? _habitsToday(List<Habit> all) {
    final today = _now();
    final scheduled = [
      for (final h in all)
        if (h.isScheduledOn(today)) h,
    ];
    if (scheduled.isEmpty) return null;
    return HabitsToday(
      habits: scheduled,
      done: scheduled.where((h) => h.isDoneOn(today)).length,
    );
  }

  MonthSpending? _spending(
    List<Transaction> txs,
    List<ExpenseCategory> categories,
  ) {
    final month = ExpenseSummary.inMonth(txs, _now()).where((t) => t.isExpense);
    final budgets = [for (final c in categories) ?c.monthlyBudget];
    if (month.isEmpty && budgets.isEmpty) return null;
    final byId = {for (final c in categories) c.id: c};
    return MonthSpending(
      spent: ExpenseSummary.total(month),
      budget: budgets.isEmpty ? null : budgets.reduce((a, b) => a + b),
      top: [
        for (final MapEntry(:key, :value) in ExpenseSummary.byCategory(
          month,
        ).entries.take(3))
          if (byId[key] case final c?) (c, value),
      ],
    );
  }

  @override
  Future<void> close() async {
    _closing = true;
    final subs = [..._subs.values];
    _subs.clear();
    await Future.wait([for (final sub in subs) sub.cancel()]);
    return super.close();
  }
}
