import 'package:daybook/core/config/environment.dart';
import 'package:daybook/core/network/api_client.dart';
import 'package:daybook/core/network/auth_interceptor.dart';
import 'package:daybook/core/network/logging_interceptor.dart';
import 'package:daybook/core/network/mock/mock_api_adapter.dart';
import 'package:daybook/core/network/mock/mock_server_state.dart';
import 'package:daybook/core/network/mock/mock_settings.dart';
import 'package:daybook/core/network/mock/routes/auth_routes.dart';
import 'package:daybook/core/routing/app_router.dart';
import 'package:daybook/core/storage/token_storage.dart';
import 'package:daybook/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:daybook/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:daybook/features/auth/domain/reposatory/auth_repository.dart';
import 'package:daybook/features/auth/domain/usecases/get_current_user.dart';
import 'package:daybook/features/auth/domain/usecases/login.dart';
import 'package:daybook/features/auth/domain/usecases/logout.dart';
import 'package:daybook/features/auth/domain/usecases/register.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_event.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies({bool testing = false}) async {
  _registerCore();
  _registerAuth();
  _registerFeatures();
}

void _registerCore() {
  getIt
    ..registerLazySingleton<MockSettings>(MockSettings.new)
    ..registerLazySingleton<MockServerState>(MockServerState.new)
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

void _registerFeatures() {}

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
    dio.httpClientAdapter = MockApiAdapter(getIt(), {
      ...AuthRoutes(getIt()).routes,
    });
  }
  if (kDebugMode) dio.interceptors.add(LoggingInterceptor());
  return dio;
}

// /// Used by tests so each test starts with an empty phone book.
// Future<void> resetDependencies() => getIt.reset();
