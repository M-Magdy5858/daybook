import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/auth/domain/entities/user.dart';
import 'package:daybook/features/auth/domain/reposatory/auth_repository.dart';

class GetCurrentUser {
  const GetCurrentUser(this._repository);
  final AuthRepository _repository;

  Future<Result<User>> call() => _repository.getCurrentUser();
}
