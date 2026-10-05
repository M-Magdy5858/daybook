import 'package:daybook/core/error/exceptions.dart';
import 'package:daybook/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _typed(DioExceptionType type) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: type,
);

DioException _status(int code, [Object? data]) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: code, data: data),
  );
}

void main() {
  group('mapDioException by type', () {
    final cases = <DioExceptionType, AppException>{
      DioExceptionType.connectionTimeout: const RequestTimeoutException(),
      DioExceptionType.receiveTimeout: const RequestTimeoutException(),
      DioExceptionType.sendTimeout: const RequestTimeoutException(),
      DioExceptionType.connectionError: const NetworkException(),
      DioExceptionType.cancel: const RequestCancelledException(),
    };

    cases.forEach((type, expected) {
      test('maps ${type.name} to ${expected.runtimeType}', () {
        expect(mapDioException(_typed(type)).runtimeType, expected.runtimeType);
      });
    });
  });

  group('mapDioException by status', () {
    test('401 uses the default message when the server sends none', () {
      final e = mapDioException(_status(401));
      expect(e, isA<AuthenticationException>());
      expect(e.message, const AuthenticationException().message);
    });

    test('401 uses the server message when present', () {
      final e = mapDioException(_status(401, {'message': 'Token expired'}));
      expect(e.message, 'Token expired');
    });

    test('403 maps to PermissionException', () {
      expect(mapDioException(_status(403)), isA<PermissionException>());
    });

    test('404 maps to NotFoundException with default message', () {
      final e = mapDioException(_status(404));
      expect(e, isA<NotFoundException>());
      expect(e.message, 'Not found');
    });

    test('409 keeps the server data', () {
      final e = mapDioException(
        _status(409, {'message': 'stale', 'version': 3}),
      );
      expect(
        e,
        isA<ConflictException>().having(
          (c) => c.serverData?['version'],
          'version',
          3,
        ),
      );
    });

    test('422 reads string field errors', () {
      final e = mapDioException(
        _status(422, {
          'errors': {'email': 'Already used'},
        }),
      );
      expect(
        e,
        isA<ValidationException>().having((v) => v.fieldErrors, 'fieldErrors', {
          'email': 'Already used',
        }),
      );
    });

    test('422 takes the first message from list field errors', () {
      final e = mapDioException(
        _status(422, {
          'message': 'Invalid',
          'errors': {
            'email': ['has already been taken', 'is too long'],
            'name': <String>[],
          },
        }),
      );
      expect(
        e,
        isA<ValidationException>().having((v) => v.fieldErrors, 'fieldErrors', {
          'email': 'has already been taken',
        }),
      );
      expect(e.message, 'Invalid');
    });

    test('422 without errors gives empty field errors', () {
      final e = mapDioException(_status(422));
      expect(
        e,
        isA<ValidationException>().having(
          (v) => v.fieldErrors,
          'fieldErrors',
          isEmpty,
        ),
      );
    });

    for (final code in [400, 429, 500, 503]) {
      test('$code maps to ServerException with its status code', () {
        expect(
          mapDioException(_status(code)),
          isA<ServerException>().having(
            (s) => s.statusCode,
            'statusCode',
            code,
          ),
        );
      });
    }

    test('no response maps to UnknownException with default message', () {
      final e = mapDioException(_typed(DioExceptionType.unknown));
      expect(e, isA<UnknownException>());
      expect(e.message, const UnknownException().message);
    });
  });
}
