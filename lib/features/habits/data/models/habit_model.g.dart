// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HabitModel _$HabitModelFromJson(Map<String, dynamic> json) => HabitModel(
  id: json['id'] as String,
  name: json['name'] as String,
  colorValue: (json['colorValue'] as num).toInt(),
  weekdays: (json['weekdays'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  reminderMinutes: (json['reminderMinutes'] as num?)?.toInt(),
  completions:
      (json['completions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  version: (json['version'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$HabitModelToJson(HabitModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'colorValue': instance.colorValue,
      'weekdays': instance.weekdays,
      'reminderMinutes': instance.reminderMinutes,
      'completions': instance.completions,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'version': instance.version,
    };
