import 'package:equatable/equatable.dart';

class Subtask extends Equatable {
  const Subtask({required this.id, required this.title, this.done = false});

  final String id;
  final String title;
  final bool done;

  Subtask copyWith({String? title, bool? done}) =>
      Subtask(id: id, title: title ?? this.title, done: done ?? this.done);

  @override
  List<Object?> get props => [id, title, done];
}
