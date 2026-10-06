import 'package:daybook/shared/models/recurrence_json.dart';
import 'package:daybook/features/tasks/domain/entities/priority.dart';
import 'package:daybook/features/tasks/domain/entities/subtask.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/shared/models/recurrence_rule.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task_model.g.dart';

@JsonSerializable()
class SubtaskModel {
  const SubtaskModel({
    required this.id,
    required this.title,
    this.done = false,
  });

  factory SubtaskModel.fromJson(Map<String, dynamic> json) =>
      _$SubtaskModelFromJson(json);
  factory SubtaskModel.fromEntity(Subtask s) =>
      SubtaskModel(id: s.id, title: s.title, done: s.done);

  final String id;
  final String title;
  final bool done;

  Map<String, dynamic> toJson() => _$SubtaskModelToJson(this);
  Subtask toEntity() => Subtask(id: id, title: title, done: done);
}

/// A task as the API sends it. Dates travel as ISO-8601 strings in UTC.
@JsonSerializable(explicitToJson: true)
class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
    this.priority = Priority.medium,
    this.dueDate,
    this.completedAt,
    this.subtasks = const [],
    this.recurrence,
    this.position = 0,
    this.estimatedMinutes,
    this.version = 0,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  factory TaskModel.fromEntity(Task t) => TaskModel(
    id: t.id,
    title: t.title,
    notes: t.notes,
    priority: t.priority,
    dueDate: t.dueDate?.toUtc(),
    completedAt: t.completedAt?.toUtc(),
    subtasks: [for (final s in t.subtasks) SubtaskModel.fromEntity(s)],
    recurrence: t.recurrence,
    position: t.position,
    estimatedMinutes: t.estimatedMinutes,
    createdAt: t.createdAt.toUtc(),
    updatedAt: t.updatedAt.toUtc(),
    version: t.version,
  );

  final String id;
  final String title;
  final String notes;
  final Priority priority;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final List<SubtaskModel> subtasks;
  @RecurrenceJson()
  final RecurrenceRule? recurrence;
  final int position;
  final int? estimatedMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

  Task toEntity() => Task(
    id: id,
    title: title,
    notes: notes,
    priority: priority,
    dueDate: dueDate?.toLocal(),
    completedAt: completedAt?.toLocal(),
    subtasks: [for (final s in subtasks) s.toEntity()],
    recurrence: recurrence,
    position: position,
    estimatedMinutes: estimatedMinutes,
    createdAt: createdAt.toLocal(),
    updatedAt: updatedAt.toLocal(),
    version: version,
  );
}
