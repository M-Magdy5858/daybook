import 'dart:async';

import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/features/calendar/domain/repositories/event_repository.dart';
import 'package:daybook/features/calendar/domain/services/occurrence_expander.dart';
import 'package:daybook/features/calendar/presentation/cubit/calendar_state.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A Cubit: no events, just methods that emit new states.
class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit(
    this._repository, {
    required this.newId,
    DateTime Function() clock = DateTime.now,
  }) : _now = clock,
       super(CalendarState.initial(clock()));

  final EventRepository _repository;
  final DateTime Function() _now;

  /// Makes ids for events split off from a series.
  final String Function() newId;

  static const _expander = OccurrenceExpander();
  StreamSubscription<List<Event>>? _sub;

  /// Start listening to the database; the calendar redraws on every change.
  void load() {
    _sub ??= _repository.watchEvents().listen(
      (events) => _emitExpanded(
        state.copyWith(events: events, status: CalendarStatus.ready),
      ),
    );
  }

  void changeView(CalendarView view) =>
      _emitExpanded(state.copyWith(view: view, focused: state.selected));

  void next() => _emitExpanded(state.copyWith(focused: _step(1)));

  void previous() => _emitExpanded(state.copyWith(focused: _step(-1)));

  void goToToday() {
    final today = _now().startOfDay;
    _emitExpanded(state.copyWith(focused: today, selected: today));
  }

  void selectDate(DateTime date) => _emitExpanded(
    state.copyWith(focused: date.startOfDay, selected: date.startOfDay),
  );

  /// Tap on a day in the month view: show that day.
  void openDay(DateTime date) => _emitExpanded(
    state.copyWith(
      focused: date.startOfDay,
      selected: date.startOfDay,
      view: CalendarView.day,
    ),
  );

  Future<void> saveEvent(Event event) =>
      _write(_repository.save(event.copyWith(updatedAt: _now())));

  Future<void> deleteEvent(String id) => _write(_repository.delete(id));

  /// Drag-to-reschedule. For a repeating event, [wholeSeries] moves every
  /// occurrence; otherwise just this one is split off into its own event.
  Future<void> moveEvent(
    EventOccurrence occurrence,
    DateTime newStart, {
    bool wholeSeries = true,
  }) async {
    final event = occurrence.event;
    final delta = newStart.difference(occurrence.start);
    if (event.recurrence == null || wholeSeries) {
      return saveEvent(
        event.copyWith(
          start: event.start.add(delta),
          end: event.end.add(delta),
        ),
      );
    }
    await saveEvent(
      event.copyWith(
        excludedDates: {...event.excludedDates, occurrence.start.startOfDay},
      ),
    );
    final now = _now();
    await saveEvent(
      Event(
        id: newId(),
        title: event.title,
        start: newStart,
        end: newStart.add(event.duration),
        allDay: event.allDay,
        colorValue: event.colorValue,
        linkedTaskId: event.linkedTaskId,
        createdAt: now,
      ),
    );
  }

  DateTime _step(int direction) {
    final f = state.focused;
    return switch (state.view) {
      CalendarView.month => DateTime(f.year, f.month + direction),
      CalendarView.week => f.addDays(7 * direction),
      CalendarView.day => f.addDays(direction),
      CalendarView.agenda => f.addDays(30 * direction),
    };
  }

  void _emitExpanded(CalendarState next) {
    final (from, to) = next.range;
    emit(next.copyWith(occurrences: _expander.expand(next.events, from, to)));
  }

  Future<void> _write(Future<Result<void>> op) async {
    if (await op case Err(:final failure)) {
      emit(state.copyWith(failure: failure));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
