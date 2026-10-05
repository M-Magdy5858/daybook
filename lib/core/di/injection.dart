import 'package:daybook/core/network/api_client.dart';
import 'package:daybook/core/network/logging_interceptor.dart';
import 'package:daybook/core/routing/app_router.dart';
import 'package:daybook/features/auth/domain/reposatory/auth_repository.dart';
import 'package:daybook/features/auth/domain/reposatory/fake_auth_repository.dart';
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
    ..registerLazySingleton<Dio>(() {
      final dio = Dio(
        BaseOptions(
          baseUrl: const String.fromEnvironment(
            'API_URL',
            defaultValue: 'https://api.daybook.dev',
          ),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          contentType: 'application/json',
        ),
      );
      if (kDebugMode) dio.interceptors.add(LoggingInterceptor());
      return dio;
    })
    ..registerLazySingleton<ApiClient>(() => ApiClient(getIt()))
    ..registerLazySingleton<GoRouter>(createAppRouter);
}

void _registerAuth() {
  getIt
    ..registerLazySingleton<AuthRepository>(FakeAuthRepository.new)
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
