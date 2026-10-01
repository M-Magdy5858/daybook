import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/auth/domain/entities/user.dart';
import 'package:daybook/features/auth/domain/reposatory/auth_repository.dart';

class Login {
  const Login(this._repository);
  final AuthRepository _repository;

  Future<Result<User>> call({required String email, required String password}) {
    return _repository.login(email: email.trim(), password: password);
  }
}
