import 'dart:async';

import 'package:daybook/core/error/error_mapper.dart';
import 'package:daybook/core/error/exceptions.dart';
import 'package:daybook/core/error/failures.dart';
import 'package:daybook/core/storage/app_database.dart';
import 'package:daybook/core/storage/outbox.dart';
import 'package:daybook/core/sync/sync_engine.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:daybook/features/expenses/data/models/expense_models.dart';
import 'package:daybook/features/expenses/domain/entities/account.dart';
import 'package:daybook/features/expenses/domain/entities/expense_category.dart';
import 'package:daybook/features/expenses/domain/entities/transaction.dart';
import 'package:daybook/features/expenses/domain/repositories/expense_repository.dart';

/// Local-first, like the other features. Accounts and categories come from
/// the server; transactions and budgets are written here and synced.
class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl({
    required this._db,
    required this._local,
    required this._outbox,
    required this._sync,
  });

  final AppDatabase _db;
  final ExpenseLocalDataSource _local;
  final Outbox _outbox;
  final SyncEngine _sync;

  @override
  Stream<List<Account>> watchAccounts() => _local.watchAccounts();

  @override
  Stream<List<ExpenseCategory>> watchCategories() => _local.watchCategories();

  @override
  Stream<List<Transaction>> watchTransactions() => _local.watchTransactions();

  @override
  Future<Result<void>> saveTransaction(Transaction t) => _write(() async {
    final exists = await _local.transactionById(t.id) != null;
    await _local.upsertTransactions([t]);
    await _outbox.add(
      entityType: 'transaction',
      entityId: t.id,
      operation: exists ? 'update' : 'create',
      payload: TransactionModel.fromEntity(t).toJson(),
    );
  });

  @override
  Future<Result<void>> deleteTransaction(String id) => _write(() async {
    await _local.deleteTransaction(id);
    await _outbox.add(
      entityType: 'transaction',
      entityId: id,
      operation: 'delete',
    );
  });

  @override
  Future<Result<void>> saveCategory(ExpenseCategory c) => _write(() async {
    await _local.upsertCategories([c]);
    await _outbox.add(
      entityType: 'category',
      entityId: c.id,
      operation: 'update',
      payload: ExpenseCategoryModel.fromEntity(c).toJson(),
    );
  });

  @override
  Future<Result<void>> pull() => _sync.pull({'category', 'transaction'});

  /// The local write and its outbox entry in one transaction, then sync.
  Future<Result<void>> _write(Future<void> Function() body) async {
    try {
      await _db.transaction(body);
      unawaited(_sync.syncNow());
      return const Success(null);
    } on AppException catch (e) {
      return Err(ErrorMapper.toFailure(e));
    } catch (_) {
      return const Err(CacheFailure());
    }
  }
}
