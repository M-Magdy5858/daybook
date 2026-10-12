import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/expenses/domain/entities/account.dart';
import 'package:daybook/features/expenses/domain/entities/expense_category.dart';
import 'package:daybook/features/expenses/domain/entities/transaction.dart';

abstract interface class ExpenseRepository {
  Stream<List<Account>> watchAccounts();
  Stream<List<ExpenseCategory>> watchCategories();
  Stream<List<Transaction>> watchTransactions();

  Future<Result<void>> saveTransaction(Transaction transaction);
  Future<Result<void>> deleteTransaction(String id);

  /// Set or change a category's monthly budget (null removes it).
  Future<Result<void>> saveCategory(ExpenseCategory category);
}
