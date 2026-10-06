import 'package:daybook/core/config/environment.dart';
import 'package:daybook/core/network/api_client.dart';
import 'package:daybook/core/network/auth_interceptor.dart';
import 'package:daybook/core/network/connectivity_service.dart';
import 'package:daybook/core/network/logging_interceptor.dart';
import 'package:daybook/core/network/mock/mock_api_adapter.dart';
import 'package:daybook/core/network/mock/mock_router.dart';
import 'package:daybook/core/network/mock/mock_server_state.dart';
import 'package:daybook/core/network/mock/mock_settings.dart';
import 'package:daybook/core/network/mock/routes/auth_routes.dart';
import 'package:daybook/core/network/mock/routes/task_routes.dart';
import 'package:daybook/core/routing/app_router.dart';
import 'package:daybook/core/storage/app_database.dart';
import 'package:daybook/core/storage/outbox.dart';
import 'package:daybook/core/storage/token_storage.dart';
import 'package:daybook/core/sync/sync_engine.dart';
import 'package:daybook/core/utils/id.dart';
import 'package:daybook/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:daybook/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:daybook/features/auth/domain/reposatory/auth_repository.dart';
import 'package:daybook/features/auth/domain/usecases/get_current_user.dart';
import 'package:daybook/features/auth/domain/usecases/login.dart';
import 'package:daybook/features/auth/domain/usecases/logout.dart';
import 'package:daybook/features/auth/domain/usecases/register.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_event.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_state.dart';
import 'package:daybook/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:daybook/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:daybook/features/tasks/data/sync/task_sync_store.dart';
import 'package:daybook/features/tasks/domain/repositories/task_repository.dart';
import 'package:daybook/features/tasks/domain/usecases/complete_task.dart';
import 'package:daybook/features/tasks/domain/usecases/delete_task.dart';
import 'package:daybook/features/tasks/domain/usecases/refresh_tasks.dart';
import 'package:daybook/features/tasks/domain/usecases/save_task.dart';
import 'package:daybook/features/tasks/domain/usecases/watch_tasks.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies({bool testing = false}) async {
  _registerCore();
  _registerAuth();
  _registerSync();
  _registerTasks();
}

/// One engine syncs every kind of item through the shared outbox.
void _registerSync() {
  getIt
    ..registerLazySingleton<TaskLocalDataSource>(
      () => TaskLocalDataSource(getIt()),
    )
    ..registerLazySingleton<SyncEngine>(
      () => SyncEngine(
        outbox: getIt(),
        api: getIt(),
        stores: [TaskSyncStore(getIt())],
        connectivity: getIt(),
      ),
      dispose: (engine) => engine.stop(),
    );
}

void _registerCore() {
  getIt
    ..registerLazySingleton<MockSettings>(MockSettings.new)
    ..registerLazySingleton<MockServerState>(MockServerState.new)
    ..registerLazySingleton<MockRouter>(() {
      final router = MockRouter();
      AuthRoutes(getIt()).register(router);
      TaskRoutes(getIt()).register(router);
      return router;
    })
    ..registerLazySingleton<AppDatabase>(
      AppDatabase.new,
      dispose: (db) => db.close(),
    )
    ..registerLazySingleton<Outbox>(() => Outbox(getIt()))
    ..registerLazySingleton<ConnectivityService>(ConnectivityPlusService.new)
    ..registerLazySingleton<TokenStorage>(
      () => SecureTokenStorage(const FlutterSecureStorage()),
    )
    ..registerLazySingleton<AuthInterceptor>(
      () => AuthInterceptor(storage: getIt(), refreshDio: _buildDio()),
    )
    ..registerLazySingleton<Dio>(
      () => _buildDio()..interceptors.insert(0, getIt<AuthInterceptor>()),
    )
    ..registerLazySingleton<ApiClient>(() => ApiClient(getIt()))
    ..registerLazySingleton<GoRouter>(() => createAppRouter(getIt()));
}

void _registerAuth() {
  getIt
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<Login>(() => Login(getIt()));

  getIt
    ..registerLazySingleton<Register>(() => Register(getIt()))
    ..registerLazySingleton<GetCurrentUser>(() => GetCurrentUser(getIt()))
    ..registerLazySingleton<Logout>(() => Logout(getIt()))
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(
        login: getIt(),
        register: getIt(),
        getCurrentUser: getIt(),
        logout: getIt(),
        sessionExpired: getIt<AuthInterceptor>().onSessionExpired,
      )..add(const SessionChecked()),
    );
}

void _registerTasks() {
  getIt
    ..registerLazySingleton<TaskRepository>(
      () => TaskRepositoryImpl(
        db: getIt(),
        local: getIt(),
        outbox: getIt(),
        sync: getIt(),
      ),
    )
    ..registerLazySingleton<WatchTasks>(() => WatchTasks(getIt()))
    ..registerLazySingleton<SaveTask>(() => SaveTask(getIt()))
    ..registerLazySingleton<DeleteTask>(() => DeleteTask(getIt()))
    ..registerLazySingleton<CompleteTask>(
      () => CompleteTask(getIt(), newId: newId),
    )
    ..registerLazySingleton<RefreshTasks>(() => RefreshTasks(getIt()))
    // A fresh Bloc each time the Tasks screen opens.
    ..registerFactory<TasksBloc>(
      () => TasksBloc(
        watchTasks: getIt(),
        saveTask: getIt(),
        deleteTask: getIt(),
        completeTask: getIt(),
        refreshTasks: getIt(),
      ),
    );
}

/// Runs background services only while someone is logged in. Called from
/// `main()` rather than [configureDependencies], because widget tests have
/// no connectivity plugin.
void startSessionServices() {
  final auth = getIt<AuthBloc>();
  final sync = getIt<SyncEngine>();
  void apply(AuthState state) => switch (state) {
    Authenticated() => sync.start(),
    Unauthenticated() => sync.stop(),
    _ => null,
  };
  apply(auth.state);
  auth.stream.listen(apply);
}

/// A Dio pointed at the mock or real API. Used for the main client and for
/// the refresh client, which must not carry the [AuthInterceptor].
Dio _buildDio() {
  final isMock = Environment.current == Environment.mock;
  final dio = Dio(
    BaseOptions(
      baseUrl: isMock ? Environment.mockBaseUrl : Environment.realBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ),
  );
  if (isMock) {
    dio.httpClientAdapter = MockApiAdapter(getIt(), getIt());
  }
  if (kDebugMode) dio.interceptors.add(LoggingInterceptor());
  return dio;
}

// /// Used by tests so each test starts with an empty phone book.
// Future<void> resetDependencies() => getIt.reset();
