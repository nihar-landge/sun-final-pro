import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/errors/failures.dart';
import 'package:feedback_app/features/auth/domain/entities/user.dart';
import 'package:feedback_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:feedback_app/features/auth/domain/usecases/login.dart';
import 'package:feedback_app/features/auth/domain/usecases/logout.dart';
import 'package:feedback_app/features/auth/domain/usecases/register.dart';
import 'package:feedback_app/features/auth/domain/usecases/restore_session.dart';

// ---------- Events ----------

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired at app start: restores a persisted session if one exists.
class AuthSessionRequested extends AuthEvent {
  const AuthSessionRequested();
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const RegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthResetRequested extends AuthEvent {}

class LogoutRequested extends AuthEvent {}

// ---------- States ----------

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class RegisterSuccess extends AuthState {
  const RegisterSuccess();
}

class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// ---------- Bloc ----------

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Register register;
  final Login login;
  final RestoreSession restoreSession;
  final Logout logout;

  AuthBloc({required AuthRepository repository})
      : register = Register(repository),
        login = Login(repository),
        restoreSession = RestoreSession(repository),
        logout = Logout(repository),
        super(const AuthInitial()) {
    on<AuthSessionRequested>(_onRestoreSession);
    on<RegisterRequested>(_onRegister);
    on<LoginRequested>(_onLogin);
    on<AuthResetRequested>((event, emit) => emit(const AuthInitial()));
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onRestoreSession(AuthSessionRequested event, Emitter<AuthState> emit) async {
    try {
      final session = await restoreSession();
      if (session != null) {
        emit(Authenticated(session.user));
      }
      // No stored session (or it is no longer valid): stay on AuthInitial.
    } on Failure {
      // Offline or backend down — the user can still try to log in.
    }
  }

  Future<void> _onRegister(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await register(name: event.name, email: event.email, password: event.password);
      emit(const RegisterSuccess());
    } on Failure catch (failure) {
      emit(AuthFailure(failure.message));
    }
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final session = await login(email: event.email, password: event.password);
      emit(Authenticated(session.user));
    } on Failure catch (failure) {
      emit(AuthFailure(failure.message));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await logout();
    emit(const AuthInitial());
  }
}
