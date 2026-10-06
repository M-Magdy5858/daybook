import 'package:daybook/core/network/api_client.dart';
import 'package:daybook/core/network/connectivity_service.dart';
import 'package:daybook/core/network/mock/mock_api_adapter.dart';
import 'package:daybook/core/network/mock/mock_router.dart';
import 'package:daybook/core/network/mock/mock_server_state.dart';
import 'package:daybook/core/network/mock/mock_settings.dart';
import 'package:daybook/core/network/mock/routes/task_routes.dart';
import 'package:daybook/core/storage/app_database.dart';
import 'package:daybook/core/storage/outbox.dart';
import 'package:daybook/core/sync/sync_engine.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:daybook/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:daybook/features/tasks/data/sync/task_sync_store.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeConnectivity implements ConnectivityService {
  @override
  Stream<bool> get onlineChanges => const Stream.empty();
}

/// Runs the real repository, sync engine and mock server against an
/// in-memory database.
void main() {
  late AppDatabase db;
  late MockSettings settings;
  late MockServerState server;
  late Outbox outbox;
  late SyncEngine engine;
  late TaskRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = MockSettings()..latency = Duration.zero;
    server = MockServerState();
    final router = MockRouter();
    TaskRoutes(server).register(router);
    final api = ApiClient(
      Dio(BaseOptions(baseUrl: 'https://mock'))
        ..httpClientAdapter = MockApiAdapter(settings, router),
    );
    final local = TaskLocalDataSource(db);
    outbox = Outbox(db);
    engine = SyncEngine(
      outbox: outbox,
      api: api,
      stores: [TaskSyncStore(local)],
      connectivity: FakeConnectivity(),
    );
    repo = TaskRepositoryImpl(
      db: db,
      local: local,
      outbox: outbox,
      sync: engine,
    );
  });
  tearDown(() => db.close());

  test(
    'offline changes queue up, then all reach the server in order',
    () async {
      settings.offline = true;
      final task = Task(id: 'a', title: 'Offline', createdAt: DateTime(2026));
      await repo.save(task);
      await repo.save(task.copyWith(title: 'Offline, edited'));
      await engine.syncNow();

      expect(await outbox.oldestFirst(), hasLength(2));
      expect(server.tasks['a'], isNull);

      settings.offline = false;
      expect(await engine.syncNow(), isA<Success<void>>());

      expect(await outbox.oldestFirst(), isEmpty);
      expect(server.tasks['a']!['title'], 'Offline, edited');
    },
  );

  test('a newer server edit wins a conflict', () async {
    await engine.syncNow(); // pull the seeded tasks
    final mine = (await repo.getById('seed-1')).fold((t) => t, (f) => throw f);

    settings.offline = true;
    await repo.save(mine.copyWith(title: 'Mine', updatedAt: DateTime(2026, 2)));
    await engine.syncNow();
    server.simulateServerEdit('seed-1'); // newer than our edit

    settings.offline = false;
    await engine.syncNow();

    final after = (await repo.getById('seed-1')).fold((t) => t, (f) => throw f);
    expect(after.title, server.tasks['seed-1']!['title']);
    expect(after.title, contains('edited on server'));
    expect(await outbox.oldestFirst(), isEmpty);
  });
}
