import 'package:daybook/features/auth/domain/usecases/login.dart';
import 'package:daybook/features/auth/domain/usecases/register.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_event.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required Login login, required Register register})
      : _login = login,
        _register = register,
        super(const AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
  }

  final Login _login;
  final Register _register;

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _login(email: event.email, password: event.password);
    emit(result.fold(Authenticated.new, AuthFailure.new));
  }

  Future<void> _onRegister(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _register(displayName: event.name, email: event.email, password: event.password);
    emit(result.fold(Authenticated.new, AuthFailure.new));
  }
}