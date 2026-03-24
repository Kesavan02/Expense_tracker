import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String avatar;
  final String currency;
  final String dateFormat;
  final String token;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar = '',
    this.currency = 'USD',
    this.dateFormat = 'MM/DD/YYYY',
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      avatar: json['avatar'] as String? ?? '',
      currency: json['currency'] as String? ?? 'USD',
      dateFormat: json['dateFormat'] as String? ?? 'MM/DD/YYYY',
      token: json['token'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, avatar, currency, dateFormat, token];
}
