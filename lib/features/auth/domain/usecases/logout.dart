import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/auth/domain/reposatory/auth_repository.dart';

class Logout {
  const Logout(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.logout();
}
