import 'package:drift/drift.dart';

/// The outbox: local changes waiting to be sent to the server, oldest first.
class PendingMutations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // 'task'
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // create / update / delete
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
}
