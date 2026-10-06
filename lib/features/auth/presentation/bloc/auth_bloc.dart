import 'dart:async';

import 'package:daybook/features/auth/domain/usecases/get_current_user.dart';
import 'package:daybook/features/auth/domain/usecases/login.dart';
import 'package:daybook/features/auth/domain/usecases/logout.dart';
import 'package:daybook/features/auth/domain/usecases/register.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_event.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this._login,
    required this._register,
    required this._getCurrentUser,
    required this._logout,
    Stream<void> sessionExpired = const Stream.empty(),
  }) : super(const AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<SessionChecked>(_onSessionChecked);
    on<LogoutRequested>(_onLogout);
    on<SessionExpired>((_, emit) => emit(const Unauthenticated()));
    _expiredSub = sessionExpired.listen((_) => add(const SessionExpired()));
  }

  final Login _login;
  final Register _register;
  final GetCurrentUser _getCurrentUser;
  final Logout _logout;
  late final StreamSubscription<void> _expiredSub;

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _login(email: event.email, password: event.password);
    emit(result.fold(Authenticated.new, AuthFailure.new));
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _register(
      displayName: event.name,
      email: event.email,
      password: event.password,
    );
    emit(result.fold(Authenticated.new, AuthFailure.new));
  }

  Future<void> _onSessionChecked(
    SessionChecked event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _getCurrentUser();
    emit(result.fold(Authenticated.new, (_) => const Unauthenticated()));
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await _logout();
    emit(const Unauthenticated());
  }

  @override
  Future<void> close() {
    _expiredSub.cancel();
    return super.close();
  }
}
