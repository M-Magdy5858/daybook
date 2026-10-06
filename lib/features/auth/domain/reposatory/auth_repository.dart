import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/auth/domain/entities/user.dart';

abstract interface class AuthRepository {
  Future<Result<User>> login({required String email, required String password});

  Future<Result<User>> register({
    required String email,
    required String password,
    required String displayName,
  });

  /// The user behind the stored session, or `UnauthorizedFailure` if none.
  Future<Result<User>> getCurrentUser();

  Future<Result<void>> logout();
}
