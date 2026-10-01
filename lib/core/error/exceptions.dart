sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

final class RequestTimeoutException extends AppException {
  const RequestTimeoutException([super.message = 'The request timed out']);
}

final class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode});

  final int? statusCode;
}

final class AuthenticationException extends AppException {
  const AuthenticationException([super.message = 'Please log in again']);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found']);
}

final class ConflictException extends AppException {
  const ConflictException(super.message, {this.serverData});

  final Map<String, dynamic>? serverData;
}

final class ValidationException extends AppException {
  const ValidationException(super.message, {this.fieldErrors = const {}});

  final Map<String, String> fieldErrors;
}

final class ParsingException extends AppException {
  const ParsingException([super.message = 'Unexpected data from server']);
}

final class DatabaseException extends AppException {
  const DatabaseException([super.message = 'Local storage error']);
}

final class PermissionException extends AppException {
  const PermissionException([super.message = 'Permission denied']);
}

final class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong']);
}