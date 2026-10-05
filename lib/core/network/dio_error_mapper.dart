import 'package:daybook/core/error/exceptions.dart';
import 'package:dio/dio.dart';

AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return const RequestTimeoutException();
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.cancel:
      return const RequestCancelledException();
    default:
      break;
  }

  final status = e.response?.statusCode;
  final data = e.response?.data;
  // Null when the server sent no message, so each exception keeps its default.
  final message = (data is Map && data['message'] is String)
      ? data['message'] as String
      : null;

  return switch (status) {
    401 =>
      message == null
          ? const AuthenticationException()
          : AuthenticationException(message),
    403 =>
      message == null
          ? const PermissionException()
          : PermissionException(message),
    404 =>
      message == null ? const NotFoundException() : NotFoundException(message),
    409 => ConflictException(
      message ?? 'This item was changed elsewhere',
      serverData: data is Map<String, dynamic> ? data : null,
    ),
    422 => ValidationException(
      message ?? 'Please check the highlighted fields',
      fieldErrors: _fieldErrors(data),
    ),
    int s when s >= 400 => ServerException(
      message ?? 'Request failed',
      statusCode: s,
    ),
    _ => message == null ? const UnknownException() : UnknownException(message),
  };
}

/// Accepts both `{"email": "taken"}` and `{"email": ["taken", ...]}`.
Map<String, String> _fieldErrors(Object? data) {
  final errors = data is Map ? data['errors'] : null;
  if (errors is! Map) return const {};
  return {
    for (final MapEntry(:key, :value) in errors.entries)
      if (value is String)
        '$key': value
      else if (value is List && value.isNotEmpty)
        '$key': '${value.first}',
  };
}
