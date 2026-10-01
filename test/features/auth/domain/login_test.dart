import 'package:daybook/core/error/failures.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/auth/domain/entities/user.dart';
import 'package:daybook/features/auth/domain/reposatory/fake_auth_repository.dart';
import 'package:daybook/features/auth/domain/usecases/login.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final login = Login(FakeAuthRepository());

  test('correct credentials -> Success', () async {
    expect(await login(email: 'demo@daybook.dev', password: 'password123'), isA<Success<User>>());
  });

  test('wrong password -> UnauthorizedFailure', () async {
    final result = await login(email: 'demo@daybook.dev', password: 'nope');
    expect((result as Err<User>).failure, isA<UnauthorizedFailure>());
  });

  test('email is trimmed', () async {
    expect(await login(email: '  demo@daybook.dev ', password: 'password123'), isA<Success<User>>());
  });
}