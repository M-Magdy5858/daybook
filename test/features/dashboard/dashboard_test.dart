import 'package:daybook/core/error/failures.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/features/calendar/domain/repositories/event_repository.dart';
import 'package:daybook/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:daybook/features/dashboard/presentation/widgets/dashboard_section.dart';
import 'package:daybook/features/expenses/domain/entities/expense_category.dart';
import 'package:daybook/features/expenses/domain/entities/transaction.dart';
import 'package:daybook/features/expenses/domain/entities/transaction_type.dart';
import 'package:daybook/features/expenses/domain/repositories/expense_repository.dart';
import 'package:daybook/features/habits/domain/entities/habit.dart';
import 'package:daybook/features/habits/domain/repositories/habit_repository.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/domain/repositories/task_repository.dart';
import 'package:daybook/features/tasks/domain/usecases/complete_task.dart';
import 'package:daybook/shared/models/money.dart';
import 'package:daybook/shared/models/section_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 12, 9);

// Fakes: one item each. Methods the Dashboard never calls fall through to
// noSuchMethod.
class _Tasks implements TaskRepository {
  Result<void> pulled = const Err(ServerFailure('Simulated 500'));
  @override
  Future<Result<void>> pull() async => pulled;
  @override
  Stream<List<Task>> watchTasks() => Stream.value([
    Task(id: 't', title: 'Pay rent', createdAt: _now, dueDate: _now),
  ]);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Events implements EventRepository {
  @override
  Future<Result<void>> pull() async => const Success(null);
  @override
  Stream<List<Event>> watchEvents() => Stream.value([
    Event(
      id: 'e',
      title: 'Lunch',
      start: _now.add(const Duration(hours: 4)),
      end: _now.add(const Duration(hours: 5)),
      createdAt: _now,
    ),
  ]);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Habits implements HabitRepository {
  @override
  Future<Result<void>> pull() async => const Success(null);
  @override
  Stream<List<Habit>> watchHabits() =>
      Stream.value([Habit(id: 'h', name: 'Read', createdAt: _now)]);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Expenses implements ExpenseRepository {
  @override
  Future<Result<void>> pull() async => const Success(null);
  @override
  Stream<List<ExpenseCategory>> watchCategories() => Stream.value(const []);
  @override
  Stream<List<Transaction>> watchTransactions() => Stream.value([
    Transaction(
      id: 'x',
      accountId: 'cash',
      categoryId: 'food',
      amount: const Money(5000),
      type: TransactionType.expense,
      date: _now,
      createdAt: _now,
    ),
  ]);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  test('a failing tasks request breaks only the tasks section', () async {
    final tasks = _Tasks();
    final cubit = DashboardCubit(
      tasks: tasks,
      events: _Events(),
      habits: _Habits(),
      expenses: _Expenses(),
      completeTask: CompleteTask(tasks, newId: () => 'id'),
      clock: () => _now,
    );

    await cubit.load();
    expect(cubit.state.todayTasks, isA<SectionError<List<Task>>>());
    expect(
      cubit.state.upcomingEvents,
      isA<SectionData<List<EventOccurrence>>>(),
    );
    expect(cubit.state.habitsToday, isA<SectionData<HabitsToday>>());
    expect(cubit.state.monthSpending, isA<SectionData<MonthSpending>>());

    // Retry reloads just that section.
    tasks.pulled = const Success(null);
    final others = cubit.state.copyWith(todayTasks: const SectionLoading());
    await cubit.retry(DashboardPart.tasks);
    expect(cubit.state.todayTasks, isA<SectionData<List<Task>>>());
    expect(cubit.state.copyWith(todayTasks: const SectionLoading()), others);
    await cubit.close();
  });

  testWidgets('DashboardSection shows each of its four states', (tester) async {
    var retried = false;
    Future<void> show(SectionState<String> state) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardSection<String>(
            title: 'Tasks',
            state: state,
            emptyText: 'Nothing due',
            onRetry: () => retried = true,
            builder: Text.new,
          ),
        ),
      ),
    );

    await show(const SectionLoading());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await show(const SectionEmpty());
    expect(find.text('Nothing due'), findsOneWidget);

    await show(const SectionError(ServerFailure('Boom')));
    expect(find.text('Boom'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);

    await show(const SectionData('Pay rent'));
    expect(find.text('Pay rent'), findsOneWidget);
  });
}
