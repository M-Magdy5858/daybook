import 'package:daybook/features/expenses/domain/entities/transaction_type.dart';
import 'package:daybook/shared/models/money.dart';
import 'package:equatable/equatable.dart';

/// Food, Transport, Salary… Named `ExpenseCategory` because Flutter already
/// has a class called `Category`.
class ExpenseCategory extends Equatable {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.type,
    required this.updatedAt,
    this.monthlyBudget,
    this.version = 0,
  });

  final String id;
  final String name;

  /// A Material icon's code point, e.g. `Icons.restaurant.codePoint`.
  final int iconCode;
  final int colorValue;
  final TransactionType type;

  /// The spending limit per month, or null for none.
  final Money? monthlyBudget;
  final DateTime updatedAt;
  final int version;

  ExpenseCategory copyWith({
    Money? monthlyBudget,
    bool clearBudget = false,
    DateTime? updatedAt,
  }) => ExpenseCategory(
    id: id,
    name: name,
    iconCode: iconCode,
    colorValue: colorValue,
    type: type,
    monthlyBudget: clearBudget ? null : (monthlyBudget ?? this.monthlyBudget),
    updatedAt: updatedAt ?? this.updatedAt,
    version: version,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    iconCode,
    colorValue,
    type,
    monthlyBudget,
    updatedAt,
    version,
  ];
}
