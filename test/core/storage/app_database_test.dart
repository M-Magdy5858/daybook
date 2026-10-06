import 'package:daybook/core/storage/app_database.dart';
import 'package:daybook/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:daybook/features/tasks/domain/entities/subtask.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TaskLocalDataSource local;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = TaskLocalDataSource(db);
  });
  tearDown(() => db.close());

  test(
    'watchAll re-emits on change, and deleting a task deletes its subtasks',
    () async {
      final task = Task(
        id: '1',
        title: 'Pack',
        createdAt: DateTime(2026),
        subtasks: const [Subtask(id: 's1', title: 'Socks')],
      );
      final watched = local.watchAll();
      final sawInsertThenDelete = expectLater(
        watched,
        emitsInOrder([
          emitsThrough(
            predicate<List<Task>>(
              (l) => l.single.subtasks.single.title == 'Socks',
            ),
          ),
          emitsThrough(isEmpty),
        ]),
      );

      await local.upsert(task);
      await pumpEventQueue();
      await local.delete('1');
      await sawInsertThenDelete;

      expect(await db.select(db.subtasks).get(), isEmpty);
    },
  );
}
