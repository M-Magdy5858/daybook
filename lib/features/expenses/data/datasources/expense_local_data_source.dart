import 'package:daybook/core/storage/app_database.dart';
import 'package:daybook/features/expenses/domain/entities/account.dart';
import 'package:daybook/features/expenses/domain/entities/expense_category.dart';
import 'package:daybook/features/expenses/domain/entities/transaction.dart';
import 'package:daybook/features/expenses/domain/entities/transaction_type.dart';
import 'package:daybook/shared/models/money.dart';
import 'package:drift/drift.dart';

typedef SyncInfo = Map<String, ({DateTime updatedAt, int version})>;

/// Reads and writes accounts, categories and transactions in SQLite.
class ExpenseLocalDataSource {
  ExpenseLocalDataSource(this._db);
  final AppDatabase _db;

  // Accounts

  Stream<List<Account>> watchAccounts() =>
      (_db.select(
        _db.accounts,
      )..orderBy([(a) => OrderingTerm.asc(a.name)])).watch().map(
        (rows) => [
          for (final r in rows)
            Account(
              id: r.id,
              name: r.name,
              currency: r.currency,
              updatedAt: r.updatedAt,
              version: r.version,
            ),
        ],
      );

  Future<void> upsertAccounts(List<Account> accounts) => _db.batch(
    (b) => b.insertAllOnConflictUpdate(_db.accounts, [
      for (final a in accounts)
        AccountsCompanion.insert(
          id: a.id,
          name: a.name,
          currency: Value(a.currency),
          updatedAt: a.updatedAt,
          version: Value(a.version),
        ),
    ]),
  );

  // Categories

  Stream<List<ExpenseCategory>> watchCategories() =>
      (_db.select(_db.expenseCategories)
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .watch()
          .map((rows) => [for (final r in rows) _category(r)]);

  Future<ExpenseCategory?> categoryById(String id) async {
    final row = await (_db.select(
      _db.expenseCategories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : _category(row);
  }

  Future<void> upsertCategories(List<ExpenseCategory> categories) => _db.batch(
    (b) => b.insertAllOnConflictUpdate(_db.expenseCategories, [
      for (final c in categories)
        ExpenseCategoriesCompanion.insert(
          id: c.id,
          name: c.name,
          iconCode: c.iconCode,
          colorValue: c.colorValue,
          type: c.type.name,
          budgetMinor: Value(c.monthlyBudget?.minor),
          currency: Value(c.monthlyBudget?.currency ?? 'EGP'),
          updatedAt: c.updatedAt,
          version: Value(c.version),
        ),
    ]),
  );

  // Transactions

  Stream<List<Transaction>> watchTransactions() =>
      (_db.select(_db.transactions)..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
          .watch()
          .map((rows) => [for (final r in rows) _transaction(r)]);

  Future<Transaction?> transactionById(String id) async {
    final row = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _transaction(row);
  }

  Future<void> upsertTransactions(List<Transaction> txs) => _db.batch(
    (b) => b.insertAllOnConflictUpdate(_db.transactions, [
      for (final t in txs)
        TransactionsCompanion.insert(
          id: t.id,
          accountId: t.accountId,
          categoryId: t.categoryId,
          amountMinor: t.amount.minor,
          currency: Value(t.amount.currency),
          type: t.type.name,
          date: t.date,
          note: Value(t.note),
          createdAt: t.createdAt,
          updatedAt: t.updatedAt,
          version: Value(t.version),
        ),
    ]),
  );

  Future<void> deleteTransaction(String id) =>
      (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();

  // Sync bookkeeping, per table

  Future<SyncInfo> syncInfo(String entityType) async => switch (entityType) {
    'account' => {
      for (final r in await _db.select(_db.accounts).get())
        r.id: (updatedAt: r.updatedAt, version: r.version),
    },
    'category' => {
      for (final r in await _db.select(_db.expenseCategories).get())
        r.id: (updatedAt: r.updatedAt, version: r.version),
    },
    _ => {
      for (final r in await _db.select(_db.transactions).get())
        r.id: (updatedAt: r.updatedAt, version: r.version),
    },
  };

  Future<void> setVersion(String entityType, String id, int version) =>
      switch (entityType) {
        'account' =>
          (_db.update(_db.accounts)..where((r) => r.id.equals(id))).write(
            AccountsCompanion(version: Value(version)),
          ),
        'category' =>
          (_db.update(_db.expenseCategories)..where((r) => r.id.equals(id)))
              .write(ExpenseCategoriesCompanion(version: Value(version))),
        _ =>
          (_db.update(_db.transactions)..where((r) => r.id.equals(id))).write(
            TransactionsCompanion(version: Value(version)),
          ),
      };

  ExpenseCategory _category(ExpenseCategoryRow r) => ExpenseCategory(
    id: r.id,
    name: r.name,
    iconCode: r.iconCode,
    colorValue: r.colorValue,
    type: TransactionType.values.byName(r.type),
    monthlyBudget: r.budgetMinor == null
        ? null
        : Money(r.budgetMinor!, currency: r.currency),
    updatedAt: r.updatedAt,
    version: r.version,
  );

  Transaction _transaction(TransactionRow r) => Transaction(
    id: r.id,
    accountId: r.accountId,
    categoryId: r.categoryId,
    amount: Money(r.amountMinor, currency: r.currency),
    type: TransactionType.values.byName(r.type),
    date: r.date,
    note: r.note,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    version: r.version,
  );
}
