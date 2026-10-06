import 'package:daybook/core/error/exceptions.dart';
import 'package:daybook/core/error/failures.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:daybook/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:daybook/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements AuthRemoteDataSource {}

void main() {
  test(
    'AuthenticationException -> Err(UnauthorizedFailure), never throws',
    () async {
      final remote = MockRemote();
      when(
        () => remote.login(any(), any()),
      ).thenThrow(const AuthenticationException('nope'));

      final result = await AuthRepositoryImpl(
        remote,
      ).login(email: 'a', password: 'b');

      expect((result as Err<User>).failure, isA<UnauthorizedFailure>());
    },
  );
}
