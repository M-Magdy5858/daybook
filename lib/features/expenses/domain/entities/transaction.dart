import 'package:daybook/features/expenses/domain/entities/transaction_type.dart';
import 'package:daybook/shared/models/money.dart';
import 'package:equatable/equatable.dart';

/// Money in or out. [amount] is always positive; [type] says which way.
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.date,
    required this.createdAt,
    this.note = '',
    DateTime? updatedAt,
    this.version = 0,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  final String accountId;
  final String categoryId;
  final Money amount;
  final TransactionType type;
  final DateTime date;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  bool get isExpense => type == TransactionType.expense;

  Transaction copyWith({DateTime? updatedAt}) => Transaction(
    id: id,
    accountId: accountId,
    categoryId: categoryId,
    amount: amount,
    type: type,
    date: date,
    note: note,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version,
  );

  @override
  List<Object?> get props => [
    id,
    accountId,
    categoryId,
    amount,
    type,
    date,
    note,
    createdAt,
    updatedAt,
    version,
  ];
}
