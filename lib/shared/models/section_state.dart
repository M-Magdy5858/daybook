import 'package:daybook/core/error/failures.dart';
import 'package:equatable/equatable.dart';

/// The four states one part of a screen can be in. Each section of a page
/// gets its own, so one slow or broken section never blocks the others.
sealed class SectionState<T> extends Equatable {
  const SectionState();

  @override
  List<Object?> get props => const [];
}

final class SectionLoading<T> extends SectionState<T> {
  const SectionLoading();
}

final class SectionEmpty<T> extends SectionState<T> {
  const SectionEmpty();
}

final class SectionData<T> extends SectionState<T> {
  const SectionData(this.data);
  final T data;

  @override
  List<Object?> get props => [data];
}

final class SectionError<T> extends SectionState<T> {
  const SectionError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
