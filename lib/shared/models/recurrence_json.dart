import 'package:daybook/shared/models/recurrence_rule.dart';
import 'package:json_annotation/json_annotation.dart';

/// Stores a [RecurrenceRule] as a small map, e.g.
/// `{'type': 'weekly', 'weekdays': [1, 4]}`.
class RecurrenceJson
    implements JsonConverter<RecurrenceRule?, Map<String, dynamic>?> {
  const RecurrenceJson();

  @override
  RecurrenceRule? fromJson(Map<String, dynamic>? json) => switch (json) {
    null => null,
    {'type': 'daily'} => const Daily(),
    {'type': 'weekly', 'weekdays': final List<dynamic> days} => Weekly(
      days.cast<int>().toSet(),
    ),
    {'type': 'monthly', 'day': final int day} => Monthly(day),
    {'type': 'everyNDays', 'n': final int n} => EveryNDays(n),
    _ => null,
  };

  @override
  Map<String, dynamic>? toJson(RecurrenceRule? rule) => switch (rule) {
    null => null,
    Daily() => {'type': 'daily'},
    Weekly(:final weekdays) => {
      'type': 'weekly',
      'weekdays': weekdays.toList()..sort(),
    },
    Monthly(:final day) => {'type': 'monthly', 'day': day},
    EveryNDays(:final n) => {'type': 'everyNDays', 'n': n},
  };
}
