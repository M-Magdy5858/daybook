// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventModel _$EventModelFromJson(Map<String, dynamic> json) => EventModel(
  id: json['id'] as String,
  title: json['title'] as String,
  start: DateTime.parse(json['start'] as String),
  end: DateTime.parse(json['end'] as String),
  colorValue: (json['colorValue'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  allDay: json['allDay'] as bool? ?? false,
  recurrence: const RecurrenceJson().fromJson(
    json['recurrence'] as Map<String, dynamic>?,
  ),
  excludedDates:
      (json['excludedDates'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  linkedTaskId: json['linkedTaskId'] as String?,
  version: (json['version'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$EventModelToJson(EventModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'allDay': instance.allDay,
      'colorValue': instance.colorValue,
      'recurrence': const RecurrenceJson().toJson(instance.recurrence),
      'excludedDates': instance.excludedDates,
      'linkedTaskId': instance.linkedTaskId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'version': instance.version,
    };
