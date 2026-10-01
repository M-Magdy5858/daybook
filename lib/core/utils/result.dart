import 'package:daybook/core/error/failures.dart';

sealed class Result<T> {
  const Result();

  R fold<R>(R Function(T val) onSuccess, R Function(Failure failure) onError) {
    return switch (this) {
      Success<T>(:final data) => onSuccess(data),
      Err<T>(:final failure) => onError(failure),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
