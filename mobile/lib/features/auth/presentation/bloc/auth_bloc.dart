import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/errors/failures.dart';
import 'package:feedback_app/features/auth/domain/entities/user.dart';
import 'package:feedback_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:feedback_app/features/auth/domain/usecases/logout.dart';
import 'package:feedback_app/features/auth/domain/usecases/restore_session.dart';
import 'package:feedback_app/features/auth/domain/usecases/send_otp.dart';
import 'package:feedback_app/features/auth/domain/usecases/verify_otp.dart';

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

class SendOtpRequested extends AuthEvent {
  final String phone;

  const SendOtpRequested(this.phone);

  @override
  List<Object?> get props => [phone];
}

class OtpVerificationRequested extends AuthEvent {
  final String phone;
  final String code;
  final String? name;

  const OtpVerificationRequested({required this.phone, required this.code, this.name});

  @override
  List<Object?> get props => [phone, code, name];
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

class OtpSent extends AuthState {
  final String phone;

  const OtpSent(this.phone);

  @override
  List<Object?> get props => [phone];
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
  final SendOtp sendOtp;
  final VerifyOtp verifyOtp;
  final RestoreSession restoreSession;
  final Logout logout;

  AuthBloc({required AuthRepository repository})
      : sendOtp = SendOtp(repository),
        verifyOtp = VerifyOtp(repository),
        restoreSession = RestoreSession(repository),
        logout = Logout(repository),
        super(const AuthInitial()) {
    on<AuthSessionRequested>(_onRestoreSession);
    on<SendOtpRequested>(_onSendOtp);
    on<OtpVerificationRequested>(_onVerifyOtp);
    on<AuthResetRequested>((event, emit) => emit(const AuthInitial()));
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onRestoreSession(AuthSessionRequested event, Emitter<AuthState> emit) async {
    try {
      final session = await restoreSession();
      if (session != null) {
        emit(Authenticated(session.user));
      }
      // No stored session (or refresh failed): stay on AuthInitial (login page).
    } on Failure {
      // Offline or backend down — the user can still try to log in.
    }
  }

  Future<void> _onSendOtp(SendOtpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final sent = await sendOtp(event.phone);
      if (!sent) {
        emit(const AuthFailure('Could not send the OTP. Try again.'));
        return;
      }
      emit(OtpSent(event.phone));
    } on Failure catch (failure) {
      emit(AuthFailure(failure.message));
    }
  }

  Future<void> _onVerifyOtp(OtpVerificationRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final session = await verifyOtp(phone: event.phone, code: event.code, name: event.name);
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
