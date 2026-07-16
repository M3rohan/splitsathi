import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitsathi/features/auth/bloc/auth_event.dart';
import 'package:splitsathi/features/auth/bloc/auth_state.dart';
import 'package:splitsathi/features/auth/repository/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _authRepository.signUp(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: _mapErrorToMessage(e),
        ),
      );
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: _mapErrorToMessage(e),
        ),
      );
    }
  }

  // Future<void> _onLogoutRequested(
  //   AuthLogoutRequested event,
  //   Emitter<AuthState> emit,
  // ) async {
  //   await _authRepository.logout();
  //   emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
  // }
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.logout();
      emit(state.copyWith(status: AuthStatus.unauthenticated, clearUser: true));
    } catch (e) {
      // Even if repository logout fails, force local state to unauthenticated
      // so the UI doesn't get stuck, and surface the error for debugging.
      // ignore: avoid_print
      print('Logout error: $e');
      emit(state.copyWith(status: AuthStatus.unauthenticated, clearUser: true));
    }
  }

  String _mapErrorToMessage(Object error) {
    final message = error.toString();
    if (message.contains('email-already-in-use')) {
      return 'This email is already registered.';
    } else if (message.contains('weak-password')) {
      return 'Password is too weak (minimum 6 characters).';
    } else if (message.contains('user-not-found') ||
        message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return 'Invalid email or password.';
    } else if (message.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    return 'Something went wrong. Please try again.';
  }
}
