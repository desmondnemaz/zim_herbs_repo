import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';

abstract class AuthRepository {
  /// Stream emitting changes to the current authenticated user
  Stream<UserModel?> get authStateChanges;

  /// Returns the current signed in user, if any
  Future<UserModel?> getCurrentUser();

  /// Sign in using real credentials (email & password)
  Future<UserModel> signInWithCredentials({
    required String email,
    required String password,
  });

  /// Sign up a new user using credentials (email & password, optional name)
  Future<UserModel> signUpWithCredentials({
    required String email,
    required String password,
    String? fullName,
  });

  /// Sign out current user
  Future<void> signOut();
}
