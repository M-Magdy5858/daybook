import 'package:daybook/core/error/failures.dart';
import 'package:daybook/features/auth/domain/entities/user.dart';
import 'package:equatable/equatable.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);
  final User user;
  @override
  List<Object?> get props => [user];
}

final class AuthFailure extends AuthState {
  const AuthFailure(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
