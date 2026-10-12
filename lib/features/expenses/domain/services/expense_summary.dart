import 'package:daybook/features/expenses/domain/entities/expense_category.dart';
import 'package:daybook/features/expenses/domain/entities/transaction.dart';
import 'package:daybook/shared/models/money.dart';

/// One month's numbers. Never stored: always worked out from transactions,
/// so they can't get out of step.
class MonthTotals {
  const MonthTotals({required this.income, required this.expenses});

  final Money income;
  final Money expenses;
  Money get remaining => income - expenses;
}

/// Pure functions over a list of transactions.
abstract final class ExpenseSummary {
  /// Like JavaScript's `reduce`: start at zero, add each amount.
  static Money total(Iterable<Transaction> txs, {String currency = 'EGP'}) =>
      txs.fold(Money(0, currency: currency), (sum, t) => sum + t.amount);

  /// Transactions dated in [month] (any day of it).
  static List<Transaction> inMonth(Iterable<Transaction> txs, DateTime month) =>
      [
        for (final t in txs)
          if (t.date.year == month.year && t.date.month == month.month) t,
      ];

  static MonthTotals monthTotals(Iterable<Transaction> txs, DateTime month) {
    final list = inMonth(txs, month);
    return MonthTotals(
      income: total(list.where((t) => !t.isExpense)),
      expenses: total(list.where((t) => t.isExpense)),
    );
  }

  /// Spending per category id, biggest first.
  static Map<String, Money> byCategory(Iterable<Transaction> txs) {
    final map = <String, Money>{};
    for (final t in txs) {
      map.update(t.categoryId, (m) => m + t.amount, ifAbsent: () => t.amount);
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  /// Expenses for the [count] months ending with [month], oldest first.
  static List<(DateTime month, Money spent)> lastMonths(
    Iterable<Transaction> txs,
    DateTime month, {
    int count = 6,
  }) => [
    for (var i = count - 1; i >= 0; i--)
      (
        DateTime(month.year, month.month - i),
        total(
          inMonth(
            txs,
            DateTime(month.year, month.month - i),
          ).where((t) => t.isExpense),
        ),
      ),
  ];

  /// How much of each budget was used in [month]: 0.8 is 80%, 1.2 is over.
  /// Only categories that have a budget.
  static Map<String, double> budgetUse(
    Iterable<Transaction> txs,
    Iterable<ExpenseCategory> categories,
    DateTime month,
  ) {
    final spent = byCategory(inMonth(txs, month).where((t) => t.isExpense));
    return {
      for (final c in categories)
        if (c.monthlyBudget case final budget? when !budget.isZero)
          c.id: (spent[c.id] ?? Money.zero).ratioOf(budget),
    };
  }
}
