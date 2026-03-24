import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_storage/local_storage.dart';
import '../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final HiveService _hiveService;

  AuthBloc({
    required AuthRepository authRepository,
    required HiveService hiveService,
  }) : _authRepository = authRepository,
       _hiveService = hiveService,
       super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthProfileUpdateRequested>(_onAuthProfileUpdateRequested);
  }

  Future<void> _onAuthCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getMe();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(event.email, event.password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAuthRegisterRequested(
      AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.register(
        event.name,
        event.email,
        event.password,
        role: event.role, // Pass the role to the repository
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAuthLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authRepository.logout();
    await _hiveService.clearAllData();
    emit(AuthUnauthenticated());
  }

  Future<void> _onAuthProfileUpdateRequested(
      AuthProfileUpdateRequested event, Emitter<AuthState> emit) async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      final oldUser = currentState.user;
      
      // We can emit a specific loading state or just AuthLoading,
      // but emitting AuthLoading might wipe out the screen if we're not careful.
      // Let's just do it simple for now. 
      // A better approach is usually emitting AuthLoading with the old user, 
      // but let's stick to simple AuthLoading.
      emit(AuthLoading());

      try {
        final updatedUser = await _authRepository.updateProfile(
          name: event.name,
          avatar: event.avatar,
          currency: event.currency,
          dateFormat: event.dateFormat,
        );
        emit(AuthAuthenticated(updatedUser));
      } catch (e) {
        emit(AuthError(e.toString().replaceAll('Exception: ', '')));
        // Yield the old user back so the UI doesn't crash to login screen
        emit(AuthAuthenticated(oldUser));
      }
    }
  }
}
