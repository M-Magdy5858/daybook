import 'package:equatable/equatable.dart';

/// How a task or event repeats. Sealed, so every `switch` over it is complete.
sealed class RecurrenceRule extends Equatable {
  const RecurrenceRule();
  @override
  List<Object?> get props => [];
}

final class Daily extends RecurrenceRule {
  const Daily();
}

final class Weekly extends RecurrenceRule {
  /// e.g. `{DateTime.monday, DateTime.thursday}`
  const Weekly(this.weekdays);
  final Set<int> weekdays;
  @override
  List<Object?> get props => [weekdays];
}

final class Monthly extends RecurrenceRule {
  /// 31 means "last day" in shorter months.
  const Monthly(this.day);
  final int day;
  @override
  List<Object?> get props => [day];
}

final class EveryNDays extends RecurrenceRule {
  const EveryNDays(this.n);
  final int n;
  @override
  List<Object?> get props => [n];
}
