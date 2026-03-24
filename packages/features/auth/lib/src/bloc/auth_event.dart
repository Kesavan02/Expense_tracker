import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    this.role = 'user',
  });

  @override
  List<Object?> get props => [name, email, password, role];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthProfileUpdateRequested extends AuthEvent {
  final String? name;
  final String? avatar;
  final String? currency;
  final String? dateFormat;

  const AuthProfileUpdateRequested({
    this.name,
    this.avatar,
    this.currency,
    this.dateFormat,
  });

  @override
  List<Object?> get props => [name, avatar, currency, dateFormat];
}
