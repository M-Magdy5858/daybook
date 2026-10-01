import 'package:daybook/core/routing/app_router.dart';
import 'package:daybook/features/auth/domain/reposatory/auth_repository.dart';
import 'package:daybook/features/auth/domain/reposatory/fake_auth_repository.dart';
import 'package:daybook/features/auth/domain/usecases/login.dart';
import 'package:dio/dio.dart';
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
    ..registerLazySingleton<Dio>(() => Dio())
    ..registerLazySingleton<GoRouter>(createAppRouter);
}

void _registerAuth() {
  getIt
    ..registerLazySingleton<AuthRepository>(FakeAuthRepository.new)
    ..registerLazySingleton<Login>(() => Login(getIt()));
}

void _registerFeatures() {}



// /// Used by tests so each test starts with an empty phone book.
// Future<void> resetDependencies() => getIt.reset();