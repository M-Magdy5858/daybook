import 'package:daybook/core/error/failures.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/auth/domain/entities/user.dart';
import 'package:daybook/features/auth/domain/reposatory/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    ); // feels like a network call
    if (email == 'demo@daybook.dev' && password == 'password123') {
      return const Success(
        User(id: '1', email: 'demo@daybook.dev', name: 'Demo'),
      );
    }
    return const Err(UnauthorizedFailure('Wrong email or password'));
  }
}
