import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/auth/domain/entities/user.dart';

abstract interface class AuthRepository {

  Future<Result<User>> login({required String email, required String password});

  Future<Result<User>> register({
    required String email,
    required String password,
    required String displayName,
  });
  
}
