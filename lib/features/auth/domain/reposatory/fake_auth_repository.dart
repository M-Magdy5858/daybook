import 'package:daybook/core/error/failures.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/auth/domain/entities/user.dart';
import 'package:daybook/features/auth/domain/reposatory/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  // Pretend database: users, plus each user's password keyed by email.
  final List<User> _users = [
    const User(id: '1', email: 'demo@daybook.dev', name: 'Demo'),
  ];
  final Map<String, String> _passwords = {'demo@daybook.dev': 'password123'};

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    ); // feels like a network call

    final user = _users.where((u) => u.email == email).firstOrNull;
    if (user == null || _passwords[email] != password) {
      return const Err(UnauthorizedFailure('Wrong email or password'));
    }

    return Success(user);
  }

  @override
  Future<Result<User>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final alreadyUsed = _users.any((u) => u.email == email);
    if (alreadyUsed) {
      return const Err(
        ValidationFailure(
          'Email already used',
          fieldErrors: {'email': 'Already used'},
        ),
      );
    }
    final User user = User(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      email: email,
      name: displayName,
    );
    _users.add(user);
    _passwords[email] = password;
    return Success(user);
  }
}
