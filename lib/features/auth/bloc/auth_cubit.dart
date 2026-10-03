import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/auth/domain/auth_repository.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<UserModel?>? _authSubscription;

  AuthCubit(this._authRepository) : super(const AuthInitial()) {
    _init();
  }

  void _init() {
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    });
  }

  void clearError() {
    if (state is AuthError) {
      emit(const Unauthenticated());
    }
  }

  Future<void> checkAuth() async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(AuthError(failure.message, failure: failure));
    }
  }

  Future<void> signInWithCredentials({
    required String email,
    required String password,
    bool requireAdmin = false,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signInWithCredentials(
        email: email,
        password: password,
      );
      if (requireAdmin && !user.role.isAdmin) {
        await _authRepository.signOut();
        const failure = Failure(
          title: 'Access Denied',
          message:
              'This account does not have administrator privileges. Please switch to the Customer tab to sign in.',
          type: FailureType.accessDenied,
        );
        emit(AuthError(failure.message, failure: failure));
        return;
      }
      emit(Authenticated(user));
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(AuthError(failure.message, failure: failure));
    }
  }

  Future<void> signUpWithCredentials({
    required String email,
    required String password,
    String? fullName,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signUpWithCredentials(
        email: email,
        password: password,
        fullName: fullName,
      );
      emit(Authenticated(user));
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(AuthError(failure.message, failure: failure));
    }
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    try {
      await _authRepository.signOut();
    } catch (_) {
      // Ignore error to ensure state transitions to unauthenticated
    } finally {
      emit(const Unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
