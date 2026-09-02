import 'package:equatable/equatable.dart';

import 'package:feedback_app/features/auth/domain/entities/user.dart';

class UserModel extends Equatable {
  final int id;
  final String phone;
  final String name;
  final String role;

  const UserModel({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] as num).toInt(),
        phone: json['phone'] as String,
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? 'CITIZEN',
      );

  User toEntity() => User(id: id, phone: phone, name: name, role: role);

  Map<String, dynamic> toJson() => {'id': id, 'phone': phone, 'name': name, 'role': role};

  @override
  List<Object?> get props => [id, phone, name, role];
}
