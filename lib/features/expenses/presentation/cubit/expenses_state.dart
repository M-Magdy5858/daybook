import 'package:daybook/core/error/failures.dart';
import 'package:daybook/features/expenses/domain/entities/account.dart';
import 'package:daybook/features/expenses/domain/entities/expense_category.dart';
import 'package:daybook/features/expenses/domain/entities/transaction.dart';
import 'package:daybook/features/expenses/domain/services/expense_summary.dart';
import 'package:daybook/shared/models/money.dart';
import 'package:equatable/equatable.dart';

enum ExpensesStatus { loading, ready }

/// Holds only the raw data plus what's selected. Every number on screen is
/// a getter that works it out, so nothing can get out of step.
class ExpensesState extends Equatable {
  const ExpensesState({
    required this.month,
    this.status = ExpensesStatus.loading,
    this.accountId,
    this.accounts = const [],
    this.categories = const [],
    this.transactions = const [],
    this.failure,
  });

  /// The first day of the selected month.
  final DateTime month;

  /// The selected account, or null for all accounts.
  final String? accountId;
  final ExpensesStatus status;
  final List<Account> accounts;
  final List<ExpenseCategory> categories;
  final List<Transaction> transactions;
  final Failure? failure;

  /// The selected account's transactions (all months).
  List<Transaction> get _forAccount => accountId == null
      ? transactions
      : [
          for (final t in transactions)
            if (t.accountId == accountId) t,
        ];

  /// What the list shows: the selected month and account, newest first.
  List<Transaction> get visible => ExpenseSummary.inMonth(_forAccount, month);

  MonthTotals get totals => ExpenseSummary.monthTotals(_forAccount, month);

  Map<String, Money> get spendingByCategory =>
      ExpenseSummary.byCategory(visible.where((t) => t.isExpense));

  List<(DateTime, Money)> get lastSixMonths =>
      ExpenseSummary.lastMonths(_forAccount, month);

  /// Budgets are per category, across all accounts.
  Map<String, double> get budgetUse =>
      ExpenseSummary.budgetUse(transactions, categories, month);

  ExpenseCategory? category(String id) =>
      categories.where((c) => c.id == id).firstOrNull;

  Account? account(String id) => accounts.where((a) => a.id == id).firstOrNull;

  ExpensesState copyWith({
    DateTime? month,
    String? accountId,
    bool allAccounts = false,
    ExpensesStatus? status,
    List<Account>? accounts,
    List<ExpenseCategory>? categories,
    List<Transaction>? transactions,
    Failure? failure,
  }) => ExpensesState(
    month: month ?? this.month,
    accountId: allAccounts ? null : (accountId ?? this.accountId),
    status: status ?? this.status,
    accounts: accounts ?? this.accounts,
    categories: categories ?? this.categories,
    transactions: transactions ?? this.transactions,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    month,
    accountId,
    status,
    accounts,
    categories,
    transactions,
    failure,
  ];
}
