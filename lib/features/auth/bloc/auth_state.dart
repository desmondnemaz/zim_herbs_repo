import 'package:equatable/equatable.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the app launches before an auth check
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Auth operation in progress (e.g. checking status, signing in, signing up)
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated with verified session and profile
class Authenticated extends AuthState {
  final UserModel user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// No user is authenticated (guest/logged out)
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// An error occurred during authentication
class AuthError extends AuthState {
  final String message;
  final Failure? failure;

  const AuthError({
    required this.message,
    this.failure,
  });

  @override
  List<Object?> get props => [message, failure];
}
