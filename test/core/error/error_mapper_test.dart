import 'package:daybook/core/error/error_mapper.dart';
import 'package:daybook/core/error/exceptions.dart';
import 'package:daybook/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMapper.toFailure', () {
    final cases = <String, (Object, Failure)>{
      'NetworkException': (
        const NetworkException(),
        const NetworkFailure('No internet connection'),
      ),
      'RequestTimeoutException': (
        const RequestTimeoutException(),
        const NetworkFailure('The request timed out'),
      ),
      'ServerException 401': (
        const ServerException('unauthorized', statusCode: 401),
        const UnauthorizedFailure('unauthorized'),
      ),
      'ServerException 403': (
        const ServerException('forbidden', statusCode: 403),
        const UnauthorizedFailure('forbidden'),
      ),
      'ServerException 404': (
        const ServerException('missing', statusCode: 404),
        const NotFoundFailure('missing'),
      ),
      'ServerException 409': (
        const ServerException('conflict', statusCode: 409),
        const ConflictFailure('conflict'),
      ),
      'ServerException 500': (
        const ServerException('boom', statusCode: 500),
        const ServerFailure('boom'),
      ),
      'ServerException without status code': (
        const ServerException('boom'),
        const ServerFailure('boom'),
      ),
      'AuthenticationException': (
        const AuthenticationException(),
        const UnauthorizedFailure('Please log in again'),
      ),
      'NotFoundException': (
        const NotFoundException(),
        const NotFoundFailure('Not found'),
      ),
      'ConflictException': (
        const ConflictException('changed', serverData: {'id': 1}),
        const ConflictFailure('changed'),
      ),
      'ValidationException': (
        const ValidationException(
          'invalid',
          fieldErrors: {'email': 'Invalid format'},
        ),
        const ValidationFailure(
          'invalid',
          fieldErrors: {'email': 'Invalid format'},
        ),
      ),
      'ParsingException': (
        const ParsingException(),
        const ServerFailure('Unexpected data from server'),
      ),
      'DatabaseException': (
        const DatabaseException(),
        const CacheFailure('Local storage error'),
      ),
      'PermissionException': (
        const PermissionException(),
        const PermissionFailure('Permission denied'),
      ),
      'UnknownException': (
        const UnknownException('weird'),
        const UnknownFailure('weird'),
      ),
      'non-AppException': (
        StateError('bad state'),
        const UnknownFailure(),
      ),
    };

    cases.forEach((name, testCase) {
      final (exception, expected) = testCase;
      test('maps $name to ${expected.runtimeType}', () {
        expect(ErrorMapper.toFailure(exception), expected);
      });
    });
  });

  group('Failure equality', () {
    test('same type and message are equal', () {
      expect(const NetworkFailure(), const NetworkFailure());
    });

    test('different messages are not equal', () {
      expect(const ServerFailure('a'), isNot(const ServerFailure('b')));
    });

    test('different types with same message are not equal', () {
      expect(const NotFoundFailure('x'), isNot(const ServerFailure('x')));
    });

    test('ValidationFailure compares fieldErrors', () {
      expect(
        const ValidationFailure('invalid', fieldErrors: {'email': 'a'}),
        isNot(const ValidationFailure('invalid', fieldErrors: {'email': 'b'})),
      );
    });
  });

  group('AppException', () {
    test('toString includes type and message', () {
      expect(
        const NotFoundException('Entry 42').toString(),
        'NotFoundException: Entry 42',
      );
    });
  });
}
