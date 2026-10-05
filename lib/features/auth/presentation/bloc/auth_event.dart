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
  const RegisterRequested({required this.name, required this.email, required this.password});
  final String name;
  final String email;
  final String password;
  @override
  List<Object?> get props => [name, email, password];
}