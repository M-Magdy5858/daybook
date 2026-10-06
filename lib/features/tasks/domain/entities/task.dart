import 'package:daybook/features/tasks/domain/entities/priority.dart';
import 'package:daybook/features/tasks/domain/entities/subtask.dart';
import 'package:daybook/shared/models/recurrence_rule.dart';
import 'package:equatable/equatable.dart';

class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.createdAt,
    this.notes = '',
    this.priority = Priority.medium,
    this.dueDate,
    this.completedAt,
    this.subtasks = const [],
    this.recurrence,
    this.position = 0,
    this.estimatedMinutes,
    DateTime? updatedAt,
    this.version = 0,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  final String title;
  final String notes;
  final Priority priority;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final List<Subtask> subtasks;
  final RecurrenceRule? recurrence;
  final int position;
  final int? estimatedMinutes;
  final DateTime createdAt;

  /// When this copy was last changed. Last-write-wins compares it.
  final DateTime updatedAt;

  /// The server's version number this copy is based on (0 = never synced).
  final int version;

  bool get isCompleted => completedAt != null;
  bool isOverdue(DateTime now) =>
      !isCompleted && dueDate != null && dueDate!.isBefore(now);
  (int done, int total) get progress =>
      (subtasks.where((s) => s.done).length, subtasks.length);

  Task copyWith({
    String? title,
    String? notes,
    Priority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? completedAt,
    bool clearCompleted = false,
    List<Subtask>? subtasks,
    RecurrenceRule? recurrence,
    bool clearRecurrence = false,
    int? position,
    int? estimatedMinutes,
    DateTime? updatedAt,
    int? version,
  }) {
    return Task(
      id: id,
      createdAt: createdAt,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      completedAt: clearCompleted ? null : (completedAt ?? this.completedAt),
      subtasks: subtasks ?? this.subtasks,
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
      position: position ?? this.position,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    notes,
    priority,
    dueDate,
    completedAt,
    subtasks,
    recurrence,
    position,
    estimatedMinutes,
    createdAt,
    updatedAt,
    version,
  ];
}
