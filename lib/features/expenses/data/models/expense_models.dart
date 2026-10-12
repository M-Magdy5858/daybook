import 'package:daybook/features/expenses/domain/entities/account.dart';
import 'package:daybook/features/expenses/domain/entities/expense_category.dart';
import 'package:daybook/features/expenses/domain/entities/transaction.dart';
import 'package:daybook/features/expenses/domain/entities/transaction_type.dart';
import 'package:daybook/shared/models/money.dart';
import 'package:json_annotation/json_annotation.dart';

part 'expense_models.g.dart';

// Money travels as whole minor units plus a currency code: {"amountMinor":
// 1250, "currency": "EGP"} is EGP 12.50. Never as a decimal number.

@JsonSerializable()
class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.currency,
    required this.updatedAt,
    this.version = 0,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);

  final String id;
  final String name;
  final String currency;
  final DateTime updatedAt;
  final int version;

  Map<String, dynamic> toJson() => _$AccountModelToJson(this);

  Account toEntity() => Account(
    id: id,
    name: name,
    currency: currency,
    updatedAt: updatedAt.toLocal(),
    version: version,
  );
}

@JsonSerializable()
class ExpenseCategoryModel {
  const ExpenseCategoryModel({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.type,
    required this.currency,
    required this.updatedAt,
    this.budgetMinor,
    this.version = 0,
  });

  factory ExpenseCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseCategoryModelFromJson(json);

  factory ExpenseCategoryModel.fromEntity(ExpenseCategory c) =>
      ExpenseCategoryModel(
        id: c.id,
        name: c.name,
        iconCode: c.iconCode,
        colorValue: c.colorValue,
        type: c.type,
        budgetMinor: c.monthlyBudget?.minor,
        currency: c.monthlyBudget?.currency ?? 'EGP',
        updatedAt: c.updatedAt.toUtc(),
        version: c.version,
      );

  final String id;
  final String name;
  final int iconCode;
  final int colorValue;
  final TransactionType type;
  final int? budgetMinor;
  final String currency;
  final DateTime updatedAt;
  final int version;

  Map<String, dynamic> toJson() => _$ExpenseCategoryModelToJson(this);

  ExpenseCategory toEntity() => ExpenseCategory(
    id: id,
    name: name,
    iconCode: iconCode,
    colorValue: colorValue,
    type: type,
    monthlyBudget: budgetMinor == null
        ? null
        : Money(budgetMinor!, currency: currency),
    updatedAt: updatedAt.toLocal(),
    version: version,
  );
}

@JsonSerializable()
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.amountMinor,
    required this.currency,
    required this.type,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.note = '',
    this.version = 0,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  factory TransactionModel.fromEntity(Transaction t) => TransactionModel(
    id: t.id,
    accountId: t.accountId,
    categoryId: t.categoryId,
    amountMinor: t.amount.minor,
    currency: t.amount.currency,
    type: t.type,
    date: t.date.toUtc(),
    note: t.note,
    createdAt: t.createdAt.toUtc(),
    updatedAt: t.updatedAt.toUtc(),
    version: t.version,
  );

  final String id;
  final String accountId;
  final String categoryId;
  final int amountMinor;
  final String currency;
  final TransactionType type;
  final DateTime date;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  Transaction toEntity() => Transaction(
    id: id,
    accountId: accountId,
    categoryId: categoryId,
    amount: Money(amountMinor, currency: currency),
    type: type,
    date: date.toLocal(),
    note: note,
    createdAt: createdAt.toLocal(),
    updatedAt: updatedAt.toLocal(),
    version: version,
  );
}
