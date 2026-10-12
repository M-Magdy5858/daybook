import 'dart:async';

import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/expenses/domain/entities/expense_category.dart';
import 'package:daybook/features/expenses/domain/entities/transaction.dart';
import 'package:daybook/features/expenses/domain/repositories/expense_repository.dart';
import 'package:daybook/features/expenses/domain/services/expense_summary.dart';
import 'package:daybook/features/expenses/presentation/cubit/expenses_state.dart';
import 'package:daybook/shared/models/money.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Called when a new expense pushes a category past its monthly budget.
typedef OnBudgetExceeded = void Function(ExpenseCategory category);

class ExpensesCubit extends Cubit<ExpensesState> {
  ExpensesCubit(
    this._repository, {
    this._onBudgetExceeded,
    DateTime Function() clock = DateTime.now,
  }) : _now = clock,
       super(ExpensesState(month: DateTime(clock().year, clock().month)));

  final ExpenseRepository _repository;
  final OnBudgetExceeded? _onBudgetExceeded;
  final DateTime Function() _now;
  final _subs = <StreamSubscription<Object?>>[];

  /// Listen to all three tables; any change redraws.
  void load() {
    if (_subs.isNotEmpty) return;
    _subs
      ..add(
        _repository.watchAccounts().listen(
          (a) => emit(state.copyWith(accounts: a)),
        ),
      )
      ..add(
        _repository.watchCategories().listen(
          (c) => emit(state.copyWith(categories: c)),
        ),
      )
      ..add(
        _repository.watchTransactions().listen(
          (t) => emit(
            state.copyWith(transactions: t, status: ExpensesStatus.ready),
          ),
        ),
      );
  }

  /// Move by [delta] months (`-1` = previous). `DateTime` rolls over years.
  void changeMonth(int delta) => emit(
    state.copyWith(
      month: DateTime(state.month.year, state.month.month + delta),
    ),
  );

  /// Show one account, or all of them with null.
  void changeAccount(String? accountId) => emit(
    state.copyWith(accountId: accountId, allAccounts: accountId == null),
  );

  Future<void> saveTransaction(Transaction t) async {
    final before = _budgetUse(state.transactions, t.date);
    final saved = t.copyWith(updatedAt: _now());
    await _write(_repository.saveTransaction(saved));
    if (!t.isExpense) return;
    final after = _budgetUse([
      ...state.transactions.where((x) => x.id != t.id),
      saved,
    ], t.date);
    final category = state.category(t.categoryId);
    final crossed =
        (before[t.categoryId] ?? 0) < 1 && (after[t.categoryId] ?? 0) >= 1;
    if (crossed && category != null) _onBudgetExceeded?.call(category);
  }

  Future<void> deleteTransaction(String id) =>
      _write(_repository.deleteTransaction(id));

  /// Set a category's monthly budget; null or zero removes it.
  Future<void> setBudget(ExpenseCategory category, Money? limit) => _write(
    _repository.saveCategory(
      category.copyWith(
        monthlyBudget: limit,
        clearBudget: limit == null || limit.isZero,
        updatedAt: _now(),
      ),
    ),
  );

  Map<String, double> _budgetUse(List<Transaction> txs, DateTime day) =>
      ExpenseSummary.budgetUse(txs, state.categories, day);

  Future<void> _write(Future<Result<void>> op) async {
    if (await op case Err(:final failure)) {
      emit(state.copyWith(failure: failure));
    }
  }

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
