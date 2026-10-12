import 'package:daybook/features/habits/domain/entities/habit.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

part 'habit_model.g.dart';

/// A habit as the API sends it. Completions travel inside it as
/// `yyyy-MM-dd` days.
@JsonSerializable()
class HabitModel {
  const HabitModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.weekdays,
    required this.createdAt,
    required this.updatedAt,
    this.reminderMinutes,
    this.completions = const [],
    this.version = 0,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) =>
      _$HabitModelFromJson(json);

  factory HabitModel.fromEntity(Habit h) => HabitModel(
    id: h.id,
    name: h.name,
    colorValue: h.colorValue,
    weekdays: h.weekdays.toList()..sort(),
    reminderMinutes: h.reminderMinutes,
    completions: [for (final d in h.completions) d.dayKey]..sort(),
    createdAt: h.createdAt.toUtc(),
    updatedAt: h.updatedAt.toUtc(),
    version: h.version,
  );

  final String id;
  final String name;
  final int colorValue;
  final List<int> weekdays;
  final int? reminderMinutes;
  final List<String> completions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  Map<String, dynamic> toJson() => _$HabitModelToJson(this);

  Habit toEntity() => Habit(
    id: id,
    name: name,
    colorValue: colorValue,
    weekdays: weekdays.toSet(),
    reminderMinutes: reminderMinutes,
    completions: {for (final d in completions) DateTime.parse(d)},
    createdAt: createdAt.toLocal(),
    updatedAt: updatedAt.toLocal(),
    version: version,
  );
}
