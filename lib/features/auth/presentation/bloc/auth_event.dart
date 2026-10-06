import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

final class LoginRequested extends AuthEvent {
  const LoginRequested({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

final class RegisterRequested extends AuthEvent {
  const RegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });
  final String name;
  final String email;
  final String password;
  @override
  List<Object?> get props => [name, email, password];
}

/// Sent once at startup: is there a stored session?
final class SessionChecked extends AuthEvent {
  const SessionChecked();
}

final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// The token refresh failed; the user has to log in again.
final class SessionExpired extends AuthEvent {
  const SessionExpired();
}
