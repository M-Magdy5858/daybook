import 'package:daybook/core/sync/sync_store.dart';
import 'package:daybook/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:daybook/features/expenses/data/models/expense_models.dart';

/// Shared plumbing for the three expense tables; each subclass only says its
/// name, path and how to save server copies.
abstract class _ExpenseSyncStore implements SyncStore {
  _ExpenseSyncStore(this.local);
  final ExpenseLocalDataSource local;

  @override
  Future<SyncInfo> syncInfo() => local.syncInfo(entityType);

  @override
  Future<int?> versionOf(String id) async => (await syncInfo())[id]?.version;

  @override
  Future<void> setVersion(String id, int version) =>
      local.setVersion(entityType, id, version);
}

class AccountSyncStore extends _ExpenseSyncStore {
  AccountSyncStore(super.local);

  @override
  String get entityType => 'account';
  @override
  String get path => '/accounts';

  @override
  Future<void> upsertJson(List<Map<String, dynamic>> items) =>
      local.upsertAccounts([
        for (final j in items) AccountModel.fromJson(j).toEntity(),
      ]);
}

class CategorySyncStore extends _ExpenseSyncStore {
  CategorySyncStore(super.local);

  @override
  String get entityType => 'category';
  @override
  String get path => '/categories';

  @override
  Future<void> upsertJson(List<Map<String, dynamic>> items) =>
      local.upsertCategories([
        for (final j in items) ExpenseCategoryModel.fromJson(j).toEntity(),
      ]);
}

class TransactionSyncStore extends _ExpenseSyncStore {
  TransactionSyncStore(super.local);

  @override
  String get entityType => 'transaction';
  @override
  String get path => '/transactions';

  @override
  Future<void> upsertJson(List<Map<String, dynamic>> items) =>
      local.upsertTransactions([
        for (final j in items) TransactionModel.fromJson(j).toEntity(),
      ]);
}
