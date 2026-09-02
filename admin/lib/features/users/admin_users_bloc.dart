import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_admin/core/api_client.dart';

/// Role management: list/search users and transition roles (admin only).
class AdminUser extends Equatable {
  final int id;
  final String phone;
  final String name;
  final String role;

  const AdminUser({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: (json['id'] as num).toInt(),
        phone: json['phone'] as String? ?? '',
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? 'CITIZEN',
      );

  @override
  List<Object?> get props => [id, phone, name, role];
}

sealed class AdminUsersEvent extends Equatable {
  const AdminUsersEvent();

  @override
  List<Object?> get props => [];
}

class AdminUsersSearched extends AdminUsersEvent {
  final String search;
  final String? role;

  const AdminUsersSearched({this.search = '', this.role});

  @override
  List<Object?> get props => [search, role];
}

class AdminUserRoleChanged extends AdminUsersEvent {
  final int userId;
  final String newRole;

  const AdminUserRoleChanged({required this.userId, required this.newRole});

  @override
  List<Object?> get props => [userId, newRole];
}

sealed class AdminUsersState extends Equatable {
  const AdminUsersState();

  @override
  List<Object?> get props => [];
}

class AdminUsersLoading extends AdminUsersState {
  final List<AdminUser> users;
  final String search;
  final String? role;

  const AdminUsersLoading([this.users = const [], this.search = '', this.role]);

  @override
  List<Object?> get props => [users, search, role];
}

class AdminUsersLoaded extends AdminUsersState {
  final List<AdminUser> users;
  final String search;
  final String? role;
  final int currentAdminId;

  const AdminUsersLoaded(this.users,
      {this.search = '', this.role, this.currentAdminId = 0});

  @override
  List<Object?> get props => [users, search, role, currentAdminId];
}

class AdminUsersMessage extends AdminUsersState {
  final List<AdminUser> users;
  final String message;
  final String search;
  final String? role;
  final int currentAdminId;

  const AdminUsersMessage(this.users, this.message,
      {this.search = '', this.role, this.currentAdminId = 0});

  @override
  List<Object?> get props => [users, message, search, role, currentAdminId];
}

class AdminUsersFailure extends AdminUsersState {
  final String message;
  final List<AdminUser> users;
  final String search;
  final String? role;

  const AdminUsersFailure(this.message, [this.users = const [], this.search = '', this.role]);

  @override
  List<Object?> get props => [message, users, search, role];
}

class AdminUsersBloc extends Bloc<AdminUsersEvent, AdminUsersState> {
  final AdminApiClient apiClient;
  int currentAdminId = 0;

  AdminUsersBloc({required this.apiClient}) : super(const AdminUsersLoading()) {
    on<AdminUsersSearched>(_onSearch);
    on<AdminUserRoleChanged>(_onRoleChange);
  }

  void setCurrentAdminId(int id) {
    currentAdminId = id;
  }

  List<AdminUser> _current(AdminUsersState state) => switch (state) {
        AdminUsersLoaded s => s.users,
        AdminUsersMessage s => s.users,
        AdminUsersLoading s => s.users,
        AdminUsersFailure s => s.users,
      };

  String _searchOf(AdminUsersState state) => switch (state) {
        AdminUsersLoaded s => s.search,
        AdminUsersMessage s => s.search,
        AdminUsersLoading s => s.search,
        AdminUsersFailure s => s.search,
      };

  String? _roleOf(AdminUsersState state) => switch (state) {
        AdminUsersLoaded s => s.role,
        AdminUsersMessage s => s.role,
        AdminUsersLoading s => s.role,
        AdminUsersFailure s => s.role,
      };

  Future<void> _onSearch(AdminUsersSearched event, Emitter<AdminUsersState> emit) async {
    emit(AdminUsersLoading(_current(state), event.search, event.role));
    try {
      final params = <String>[
        if (event.search.trim().isNotEmpty) 'search=${Uri.encodeQueryComponent(event.search.trim())}',
        if (event.role != null) 'role=${event.role}',
        'size=50',
      ];
      final data = await apiClient.request('/auth/admin/users?${params.join('&')}');
      final content = data is Map<String, dynamic> ? data['content'] : data;
      final users = (content as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AdminUser.fromJson)
          .toList();
      emit(AdminUsersLoaded(users,
          search: event.search, role: event.role, currentAdminId: currentAdminId));
    } on AdminApiException catch (e) {
      emit(AdminUsersFailure(e.message, _current(state), event.search, event.role));
    }
  }

  Future<void> _onRoleChange(AdminUserRoleChanged event, Emitter<AdminUsersState> emit) async {
    final users = _current(state);
    final search = _searchOf(state);
    final role = _roleOf(state);
    try {
      await apiClient.request('/auth/admin/users/${event.userId}/role',
          method: 'PATCH', body: {'newRole': event.newRole});
      final updated = users
          .map((u) => u.id == event.userId ? AdminUser(id: u.id, phone: u.phone, name: u.name, role: event.newRole) : u)
          .toList();
      emit(AdminUsersMessage(updated, 'Role updated to ${event.newRole}',
          search: search, role: role, currentAdminId: currentAdminId));
    } on AdminApiException catch (e) {
      emit(AdminUsersFailure(e.message, users, search, role));
    }
  }
}
