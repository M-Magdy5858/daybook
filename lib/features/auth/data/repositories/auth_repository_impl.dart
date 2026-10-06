import 'package:daybook/core/error/error_mapper.dart';
import 'package:daybook/core/error/failures.dart';
import 'package:daybook/core/storage/token_storage.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:daybook/features/auth/data/models/auth_response.dart';
import 'package:daybook/features/auth/domain/entities/user.dart';
import 'package:daybook/features/auth/domain/reposatory/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._tokens);
  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) => _startSession(() => _remote.login(email, password));

  @override
  Future<Result<User>> register({
    required String email,
    required String password,
    required String displayName,
  }) => _startSession(() => _remote.register(displayName, email, password));

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      if (await _tokens.readAccess() == null) {
        return const Err(UnauthorizedFailure('Not logged in'));
      }
      final user = await _remote.me();
      return Success(user.toEntity());
    } catch (e) {
      return Err(ErrorMapper.toFailure(e));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _remote.logout();
    } catch (_) {
      // Logging out locally must work even if the server can't be reached.
    }
    try {
      await _tokens.clear();
      return const Success(null);
    } catch (e) {
      return Err(ErrorMapper.toFailure(e));
    }
  }

  Future<Result<User>> _startSession(
    Future<AuthResponse> Function() request,
  ) async {
    try {
      final response = await request();
      await _tokens.save(
        access: response.accessToken,
        refresh: response.refreshToken,
      );
      return Success(response.user.toEntity());
    } catch (e) {
      return Err(ErrorMapper.toFailure(e));
    }
  }
}
