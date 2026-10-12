// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountModel _$AccountModelFromJson(Map<String, dynamic> json) => AccountModel(
  id: json['id'] as String,
  name: json['name'] as String,
  currency: json['currency'] as String,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  version: (json['version'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AccountModelToJson(AccountModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'currency': instance.currency,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'version': instance.version,
    };

ExpenseCategoryModel _$ExpenseCategoryModelFromJson(
  Map<String, dynamic> json,
) => ExpenseCategoryModel(
  id: json['id'] as String,
  name: json['name'] as String,
  iconCode: (json['iconCode'] as num).toInt(),
  colorValue: (json['colorValue'] as num).toInt(),
  type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
  currency: json['currency'] as String,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  budgetMinor: (json['budgetMinor'] as num?)?.toInt(),
  version: (json['version'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ExpenseCategoryModelToJson(
  ExpenseCategoryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'iconCode': instance.iconCode,
  'colorValue': instance.colorValue,
  'type': _$TransactionTypeEnumMap[instance.type]!,
  'budgetMinor': instance.budgetMinor,
  'currency': instance.currency,
  'updatedAt': instance.updatedAt.toIso8601String(),
  'version': instance.version,
};

const _$TransactionTypeEnumMap = {
  TransactionType.expense: 'expense',
  TransactionType.income: 'income',
};

TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    TransactionModel(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      categoryId: json['categoryId'] as String,
      amountMinor: (json['amountMinor'] as num).toInt(),
      currency: json['currency'] as String,
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      note: json['note'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TransactionModelToJson(TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'accountId': instance.accountId,
      'categoryId': instance.categoryId,
      'amountMinor': instance.amountMinor,
      'currency': instance.currency,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'date': instance.date.toIso8601String(),
      'note': instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'version': instance.version,
    };
