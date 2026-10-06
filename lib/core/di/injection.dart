import 'package:daybook/core/config/environment.dart';
import 'package:daybook/core/network/api_client.dart';
import 'package:daybook/core/network/logging_interceptor.dart';
import 'package:daybook/core/network/mock/mock_api_adapter.dart';
import 'package:daybook/core/network/mock/mock_server_state.dart';
import 'package:daybook/core/network/mock/mock_settings.dart';
import 'package:daybook/core/network/mock/routes/auth_routes.dart';
import 'package:daybook/core/routing/app_router.dart';
import 'package:daybook/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:daybook/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:daybook/features/auth/domain/reposatory/auth_repository.dart';
import 'package:daybook/features/auth/domain/usecases/login.dart';
import 'package:daybook/features/auth/domain/usecases/register.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    ..registerLazySingleton<Dio>(() {
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
    })
    ..registerLazySingleton<ApiClient>(() => ApiClient(getIt()))
    ..registerLazySingleton<GoRouter>(createAppRouter);
}

void _registerAuth() {
  getIt
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()))
    ..registerLazySingleton<Login>(() => Login(getIt()));

  getIt
    ..registerLazySingleton<Register>(() => Register(getIt()))
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(login: getIt(), register: getIt()),
    );
}

void _registerFeatures() {}

// /// Used by tests so each test starts with an empty phone book.
// Future<void> resetDependencies() => getIt.reset();
