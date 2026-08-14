import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';

abstract class AuthRepository {
  /// Stream emitting changes to the current authenticated user
  Stream<UserModel?> get authStateChanges;

  /// Returns the current signed in user, if any
  Future<UserModel?> getCurrentUser();

  /// Sign in using credentials (email & password)
  Future<UserModel> signInWithCredentials({
    required String email,
    required String password,
  });

  /// Quick sign in with a specific fake role (for demo/testing)
  Future<UserModel> signInWithFakeRole(UserRole role);

  /// Sign out current user
  Future<void> signOut();
}
