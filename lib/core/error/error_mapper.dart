import 'package:daybook/core/error/exceptions.dart';
import 'package:daybook/core/error/failures.dart';

abstract final class ErrorMapper {
  static Failure toFailure(Object e) {
    return switch (e) {
      NetworkException(:final message) => NetworkFailure(message),
      RequestTimeoutException(:final message) => NetworkFailure(message),
      RequestCancelledException(:final message) => CancelledFailure(message),
      ServerException(statusCode: 401 || 403, :final message) =>
        UnauthorizedFailure(message),
      ServerException(statusCode: 404, :final message) => NotFoundFailure(
        message,
      ),
      ServerException(statusCode: 409, :final message) => ConflictFailure(
        message,
      ),
      ServerException(:final message) => ServerFailure(message),
      AuthenticationException(:final message) => UnauthorizedFailure(message),
      NotFoundException(:final message) => NotFoundFailure(message),
      ConflictException(:final message) => ConflictFailure(message),
      ValidationException(:final message, :final fieldErrors) =>
        ValidationFailure(message, fieldErrors: fieldErrors),
      ParsingException(:final message) => ServerFailure(message),
      DatabaseException(:final message) => CacheFailure(message),
      PermissionException(:final message) => PermissionFailure(message),
      UnknownException(:final message) => UnknownFailure(message),
      _ => const UnknownFailure(),
    };
  }
}
