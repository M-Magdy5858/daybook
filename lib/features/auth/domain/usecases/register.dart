import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/auth/domain/entities/user.dart';
import 'package:daybook/features/auth/domain/reposatory/auth_repository.dart';

class Register {
  const Register(this._repository);
  final AuthRepository _repository;

  Future<Result<User>> call({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _repository.register(
      email: email.trim(),
      password: password,
      displayName: displayName,
    );
  }
}
