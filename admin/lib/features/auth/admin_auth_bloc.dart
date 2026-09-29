import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_admin/core/api_client.dart';

/// Admin session: OTP login via auth-service, gated on the ADMIN role.
sealed class AdminAuthEvent extends Equatable {
  const AdminAuthEvent();

  @override
  List<Object?> get props => [];
}

class AdminOtpSendRequested extends AdminAuthEvent {
  final String phone;

  const AdminOtpSendRequested(this.phone);

  @override
  List<Object?> get props => [phone];
}

class AdminOtpVerifyRequested extends AdminAuthEvent {
  final String phone;
  final String code;

  const AdminOtpVerifyRequested({required this.phone, required this.code});

  @override
  List<Object?> get props => [phone, code];
}

class AdminLogoutRequested extends AdminAuthEvent {}

sealed class AdminAuthState extends Equatable {
  const AdminAuthState();

  @override
  List<Object?> get props => [];
}

class AdminAuthInitial extends AdminAuthState {
  const AdminAuthInitial();
}

class AdminAuthLoading extends AdminAuthState {
  const AdminAuthLoading();
}

class AdminOtpSent extends AdminAuthState {
  final String phone;

  const AdminOtpSent(this.phone);

  @override
  List<Object?> get props => [phone];
}

class AdminAuthenticated extends AdminAuthState {
  final String name;
  final int userId;
  final String role; // ADMIN or MODERATOR — drives sidebar visibility

  const AdminAuthenticated(this.name, {this.userId = 0, this.role = 'ADMIN'});

  bool get isAdmin => role == 'ADMIN';
  bool get isModerator => role == 'MODERATOR';

  @override
  List<Object?> get props => [name, userId, role];
}

class AdminAccessDenied extends AdminAuthState {
  const AdminAccessDenied();
}

class AdminAuthFailure extends AdminAuthState {
  final String message;

  const AdminAuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminAuthBloc extends Bloc<AdminAuthEvent, AdminAuthState> {
  final AdminApiClient apiClient;

  AdminAuthBloc({required this.apiClient}) : super(const AdminAuthInitial()) {
    on<AdminOtpSendRequested>(_onSendOtp);
    on<AdminOtpVerifyRequested>(_onVerifyOtp);
    on<AdminLogoutRequested>(_onLogout);
  }

  Future<void> _onSendOtp(AdminOtpSendRequested event, Emitter<AdminAuthState> emit) async {
    emit(const AdminAuthLoading());
    try {
      await apiClient.request('/auth/otp/send',
          method: 'POST', body: {'phone': event.phone}, authenticated: false);
      emit(AdminOtpSent(event.phone));
    } on AdminApiException catch (e) {
      emit(AdminAuthFailure(e.message));
    }
  }

  Future<void> _onVerifyOtp(AdminOtpVerifyRequested event, Emitter<AdminAuthState> emit) async {
    emit(const AdminAuthLoading());
    try {
      final data = await apiClient.request('/auth/otp/verify',
          method: 'POST',
          body: {'phone': event.phone, 'code': event.code},
          authenticated: false);
      await apiClient.saveTokens(
        access: data['accessToken'] as String,
        refresh: data['refreshToken'] as String,
      );
      final me = await apiClient.request('/auth/me');
      final role = me['role'] as String? ?? 'CITIZEN';
      if (role != 'ADMIN' && role != 'MODERATOR') {
        await apiClient.clearTokens();
        emit(const AdminAccessDenied());
        return;
      }
      emit(AdminAuthenticated(
        me['name'] as String? ?? 'Staff',
        userId: (me['id'] as num?)?.toInt() ?? 0,
        role: role,
      ));
    } on AdminApiException catch (e) {
      emit(AdminAuthFailure(e.message));
    }
  }

  Future<void> _onLogout(AdminLogoutRequested event, Emitter<AdminAuthState> emit) async {
    await apiClient.logout();
    emit(const AdminAuthInitial());
  }
}
