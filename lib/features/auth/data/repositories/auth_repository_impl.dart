import 'package:daybook/core/error/error_mapper.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:daybook/features/auth/domain/entities/user.dart';
import 'package:daybook/features/auth/domain/reposatory/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);
  final AuthRemoteDataSource _remote;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remote.login(email, password);
      return Success(response.user.toEntity());
    } catch (e) {
      return Err(ErrorMapper.toFailure(e));
    }
  }

  @override
  Future<Result<User>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _remote.register(displayName, email, password);
      return Success(response.user.toEntity());
    } catch (e) {
      return Err(ErrorMapper.toFailure(e));
    }
  }
}
