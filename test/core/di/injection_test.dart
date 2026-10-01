import 'package:daybook/core/di/injection.dart';
import 'package:daybook/features/auth/domain/reposatory/auth_repository.dart';
import 'package:daybook/features/auth/domain/reposatory/fake_auth_repository.dart';
import 'package:daybook/features/auth/domain/usecases/login.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUp(configureDependencies);
  tearDown(() => getIt.reset());

  test('everything registered can be resolved', () {
    expect(getIt<Dio>(), isA<Dio>());
    expect(getIt<GoRouter>(), isA<GoRouter>());
    expect(getIt<AuthRepository>(), isA<FakeAuthRepository>());
    expect(getIt<Login>(), isA<Login>());
  });
}