// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubtaskModel _$SubtaskModelFromJson(Map<String, dynamic> json) => SubtaskModel(
  id: json['id'] as String,
  title: json['title'] as String,
  done: json['done'] as bool? ?? false,
);

Map<String, dynamic> _$SubtaskModelToJson(SubtaskModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'done': instance.done,
    };

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => TaskModel(
  id: json['id'] as String,
  title: json['title'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  notes: json['notes'] as String? ?? '',
  priority:
      $enumDecodeNullable(_$PriorityEnumMap, json['priority']) ??
      Priority.medium,
  dueDate: json['dueDate'] == null
      ? null
      : DateTime.parse(json['dueDate'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  subtasks:
      (json['subtasks'] as List<dynamic>?)
          ?.map((e) => SubtaskModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  recurrence: const RecurrenceJson().fromJson(
    json['recurrence'] as Map<String, dynamic>?,
  ),
  position: (json['position'] as num?)?.toInt() ?? 0,
  estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
  version: (json['version'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TaskModelToJson(TaskModel instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'notes': instance.notes,
  'priority': _$PriorityEnumMap[instance.priority]!,
  'dueDate': instance.dueDate?.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'subtasks': instance.subtasks.map((e) => e.toJson()).toList(),
  'recurrence': const RecurrenceJson().toJson(instance.recurrence),
  'position': instance.position,
  'estimatedMinutes': instance.estimatedMinutes,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'version': instance.version,
};

const _$PriorityEnumMap = {
  Priority.low: 'low',
  Priority.medium: 'medium',
  Priority.high: 'high',
};
