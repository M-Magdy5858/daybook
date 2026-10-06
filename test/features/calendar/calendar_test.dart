import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/features/calendar/domain/repositories/event_repository.dart';
import 'package:daybook/features/calendar/domain/services/occurrence_expander.dart';
import 'package:daybook/features/calendar/presentation/cubit/calendar_cubit.dart';
import 'package:daybook/features/calendar/presentation/cubit/calendar_state.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:daybook/shared/models/recurrence_rule.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoEvents implements EventRepository {
  @override
  Stream<List<Event>> watchEvents() => Stream.value(const []);
  @override
  Future<Result<void>> save(Event event) async => const Success(null);
  @override
  Future<Result<void>> delete(String id) async => const Success(null);
}

void main() {
  test('date helpers handle leap years and month boundaries', () {
    expect(DateTime(2028, 2, 10).daysInMonth, 29);
    expect(DateTime(2027, 2, 10).daysInMonth, 28);
    expect(DateTime(2026, 10, 31).addDays(1), DateTime(2026, 11));
    // Sunday 2026-11-01 belongs to the week starting Monday 2026-10-26.
    expect(DateTime(2026, 11, 1).startOfWeek, DateTime(2026, 10, 26));
  });

  test(
    'a weekly event over 5 weeks gives 5 occurrences, skipping excluded days',
    () {
      final standup = Event(
        id: 'e',
        title: 'Stand-up',
        start: DateTime(2026, 10, 5, 10), // a Monday
        end: DateTime(2026, 10, 5, 10, 30),
        createdAt: DateTime(2026),
        recurrence: const Weekly({DateTime.monday}),
      );
      const expander = OccurrenceExpander();
      final from = DateTime(2026, 10, 5);
      final to = from.addDays(35);

      expect(expander.expand([standup], from, to), hasLength(5));
      final skipped = standup.copyWith(excludedDates: {DateTime(2026, 10, 12)});
      expect(expander.expand([skipped], from, to), hasLength(4));
    },
  );

  test('next() moves a month in month view and 7 days in week view', () {
    final cubit = CalendarCubit(
      _NoEvents(),
      newId: () => 'x',
      clock: () => DateTime(2026, 10, 15),
    );
    addTearDown(cubit.close);

    cubit.next();
    expect(cubit.state.focused, DateTime(2026, 11));

    cubit
      ..selectDate(DateTime(2026, 10, 15))
      ..changeView(CalendarView.week)
      ..next();
    expect(cubit.state.focused, DateTime(2026, 10, 22));
  });
}
