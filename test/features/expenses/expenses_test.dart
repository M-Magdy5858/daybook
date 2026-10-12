import 'dart:async';

import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/expenses/domain/entities/account.dart';
import 'package:daybook/features/expenses/domain/entities/expense_category.dart';
import 'package:daybook/features/expenses/domain/entities/transaction.dart';
import 'package:daybook/features/expenses/domain/entities/transaction_type.dart';
import 'package:daybook/features/expenses/domain/repositories/expense_repository.dart';
import 'package:daybook/features/expenses/domain/services/expense_summary.dart';
import 'package:daybook/features/expenses/presentation/cubit/expenses_cubit.dart';
import 'package:daybook/shared/models/money.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _tx(String id, String category, int pounds, DateTime date) =>
    Transaction(
      id: id,
      accountId: 'cash',
      categoryId: category,
      amount: Money(pounds * 100),
      type: TransactionType.expense,
      date: date,
      createdAt: date,
    );

final _food = ExpenseCategory(
  id: 'food',
  name: 'Food',
  iconCode: 0,
  colorValue: 0,
  type: TransactionType.expense,
  monthlyBudget: const Money(10000), // EGP 100
  updatedAt: DateTime(2026),
);

class _Memory implements ExpenseRepository {
  _Memory(this.txs);
  List<Transaction> txs;
  final _changes = StreamController<List<Transaction>>.broadcast();

  @override
  Stream<List<Account>> watchAccounts() => Stream.value(const []);
  @override
  Stream<List<ExpenseCategory>> watchCategories() => Stream.value([_food]);
  @override
  Stream<List<Transaction>> watchTransactions() async* {
    yield txs;
    yield* _changes.stream;
  }

  @override
  Future<Result<void>> saveTransaction(Transaction t) async {
    _changes.add(txs = [...txs, t]);
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteTransaction(String id) async =>
      const Success(null);
  @override
  Future<Result<void>> saveCategory(ExpenseCategory c) async =>
      const Success(null);
}

void main() {
  final txs = [
    _tx('1', 'food', 50, DateTime(2026, 10, 2)),
    _tx('2', 'food', 30, DateTime(2026, 10, 20)),
    _tx('3', 'bills', 200, DateTime(2026, 10, 3)),
    _tx('4', 'food', 999, DateTime(2026, 9, 30)), // last month
  ];

  test("a month's total ignores other months; byCategory groups", () {
    final october = ExpenseSummary.monthTotals(txs, DateTime(2026, 10));
    expect(october.expenses, const Money(28000));
    expect(
      ExpenseSummary.byCategory(
        ExpenseSummary.inMonth(txs, DateTime(2026, 10)),
      ),
      {'bills': const Money(20000), 'food': const Money(8000)},
    );
  });

  test('changing month recomputes the summary', () async {
    final cubit = ExpensesCubit(
      _Memory(txs),
      clock: () => DateTime(2026, 10, 25),
    )..load();
    addTearDown(cubit.close);
    await pumpEventQueue();
    expect(cubit.state.totals.expenses, const Money(28000));

    cubit.changeMonth(-1);
    expect(cubit.state.month, DateTime(2026, 9));
    expect(cubit.state.totals.expenses, const Money(99900));
  });

  test('crossing 100% of a budget alerts once', () async {
    final alerts = <String>[];
    final cubit = ExpensesCubit(
      _Memory(txs), // food is at EGP 80 of 100 this month
      onBudgetExceeded: (c) => alerts.add(c.name),
      clock: () => DateTime(2026, 10, 25),
    )..load();
    addTearDown(cubit.close);
    await pumpEventQueue();

    await cubit.saveTransaction(_tx('5', 'food', 10, DateTime(2026, 10, 25)));
    await pumpEventQueue();
    expect(alerts, isEmpty); // 90%
    await cubit.saveTransaction(_tx('6', 'food', 20, DateTime(2026, 10, 25)));
    await pumpEventQueue();
    expect(alerts, ['Food']); // 110%
    await cubit.saveTransaction(_tx('7', 'food', 5, DateTime(2026, 10, 25)));
    await pumpEventQueue();
    expect(alerts, ['Food']); // already over: no repeat
  });
}
