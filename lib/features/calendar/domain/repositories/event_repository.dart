import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/calendar/domain/entities/event.dart';

abstract interface class EventRepository {
  /// Every event, re-emitted whenever any of them changes.
  Stream<List<Event>> watchEvents();
  Future<Result<void>> save(Event event);
  Future<Result<void>> delete(String id);
}
