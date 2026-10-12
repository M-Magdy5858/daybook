import 'package:equatable/equatable.dart';

class Habit extends Equatable {
  const Habit({
    required this.id,
    required this.name,
    required this.createdAt,
    this.colorValue = 0xFF43A047,
    this.weekdays = everyDay,
    this.reminderMinutes,
    this.completions = const {},
    DateTime? updatedAt,
    this.version = 0,
  }) : updatedAt = updatedAt ?? createdAt;

  static const everyDay = {1, 2, 3, 4, 5, 6, 7};

  final String id;
  final String name;

  /// An ARGB color, e.g. `0xFF43A047`.
  final int colorValue;

  /// The days it's scheduled on (`DateTime.monday` … `DateTime.sunday`).
  final Set<int> weekdays;

  /// Minutes after midnight for a daily reminder (e.g. 8:30 → 510), or null.
  final int? reminderMinutes;

  /// Days it was done, each at midnight. Only the date matters.
  final Set<DateTime> completions;

  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  bool get isEveryDay => weekdays.length == 7;
  bool isScheduledOn(DateTime day) => weekdays.contains(day.weekday);
  bool isDoneOn(DateTime day) =>
      completions.contains(DateTime(day.year, day.month, day.day));

  Habit copyWith({
    String? name,
    int? colorValue,
    Set<int>? weekdays,
    int? reminderMinutes,
    bool clearReminder = false,
    Set<DateTime>? completions,
    DateTime? updatedAt,
    int? version,
  }) => Habit(
    id: id,
    createdAt: createdAt,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    weekdays: weekdays ?? this.weekdays,
    reminderMinutes: clearReminder
        ? null
        : (reminderMinutes ?? this.reminderMinutes),
    completions: completions ?? this.completions,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    colorValue,
    weekdays,
    reminderMinutes,
    completions,
    createdAt,
    updatedAt,
    version,
  ];
}
