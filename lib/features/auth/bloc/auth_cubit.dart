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
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        if (state is! AuthError) {
          emit(const Unauthenticated());
        }
      }
    });
  }

  /// Check current session status on app start
  Future<void> checkAuth() async {
    try {
      emit(const AuthLoading());
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (e, st) {
      final failure = ErrorHandler.handle(e, st);
      emit(AuthError(message: failure.message, failure: failure));
    }
  }

  /// Sign in using credentials
  Future<void> signInWithCredentials({
    required String email,
    required String password,
    bool requireAdmin = false,
  }) async {
    try {
      emit(const AuthLoading());
      final user = await _authRepository.signInWithCredentials(
        email: email,
        password: password,
      );

      if (requireAdmin && !user.canModerate) {
        // User logged in successfully, but lacks staff/admin/moderator permissions for this portal
        await _authRepository.signOut();
        const failure = Failure(
          title: 'Access Denied',
          message:
              'This account does not have staff or administrator privileges. Please sign in via the Customer portal.',
          type: FailureType.accessDenied,
        );
        emit(AuthError(message: failure.message, failure: failure));
        return;
      }

      emit(Authenticated(user));
    } catch (e, st) {
      final failure = ErrorHandler.handle(e, st);
      emit(AuthError(message: failure.message, failure: failure));
    }
  }

  /// Convenience alias for [signInWithCredentials]
  Future<void> login({
    required String email,
    required String password,
    bool requireAdmin = false,
  }) =>
      signInWithCredentials(
        email: email,
        password: password,
        requireAdmin: requireAdmin,
      );

  /// Sign up a new user account with complete metadata
  Future<void> signUpWithCredentials({
    required String email,
    required String password,
    String? fullName,
    String? username,
    String? phoneNumber,
    String? location,
    String? primaryRole,
    List<String>? healthInterests,
    String? bio,
    String? practitionerSpecialisation,
    int? practitionerYearsOfExperience,
    String? supplierName,
    String? supplierLocation,
    String? supplierCategories,
    int? supplierYearsInOperation,
    bool applySupplier = false,
  }) async {
    try {
      emit(const AuthLoading());
      final user = await _authRepository.signUpWithCredentials(
        email: email,
        password: password,
        fullName: fullName,
        username: username,
        phoneNumber: phoneNumber,
        location: location,
        primaryRole: primaryRole,
        healthInterests: healthInterests,
        bio: bio,
        practitionerSpecialisation: practitionerSpecialisation,
        practitionerYearsOfExperience: practitionerYearsOfExperience,
        supplierName: supplierName,
        supplierLocation: supplierLocation,
        supplierCategories: supplierCategories,
        supplierYearsInOperation: supplierYearsInOperation,
        applySupplier: applySupplier,
      );
      emit(Authenticated(user));
    } catch (e, st) {
      final failure = ErrorHandler.handle(e, st);
      emit(AuthError(message: failure.message, failure: failure));
    }
  }

  /// Update user profile
  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      emit(const AuthLoading());
      final user = await _authRepository.updateProfile(updatedUser);
      emit(Authenticated(user));
    } catch (e, st) {
      final failure = ErrorHandler.handle(e, st);
      emit(AuthError(message: failure.message, failure: failure));
    }
  }

  /// Apply for herbalist practitioner verification
  Future<void> applyForPractitioner({
    required String specialisation,
    required int yearsOfExperience,
    String? location,
    String? phoneNumber,
  }) async {
    try {
      emit(const AuthLoading());
      await _authRepository.applyForPractitioner(
        specialisation: specialisation,
        yearsOfExperience: yearsOfExperience,
        location: location,
        phoneNumber: phoneNumber,
      );
      // Auth repository notifies authStateChanges stream with refreshed user
    } catch (e, st) {
      final failure = ErrorHandler.handle(e, st);
      emit(AuthError(message: failure.message, failure: failure));
    }
  }

  /// Apply for marketplace supplier status (queued for admin approval before publishing)
  Future<void> applyForSupplier({
    required String businessName,
    String? location,
    String? categories,
    int? yearsInOperation,
    String? contactPhone,
    String? bio,
    String? description,
  }) async {
    try {
      emit(const AuthLoading());
      await _authRepository.applyForSupplier(
        businessName: businessName,
        location: location,
        categories: categories,
        yearsInOperation: yearsInOperation,
        contactPhone: contactPhone,
        bio: bio,
        description: description,
      );
      // Auth repository notifies authStateChanges stream with refreshed user
    } catch (e, st) {
      final failure = ErrorHandler.handle(e, st);
      emit(AuthError(message: failure.message, failure: failure));
    }
  }

  /// Check practitioner application verification status
  Future<String?> getPractitionerApplicationStatus(String userId) {
    return _authRepository.getPractitionerApplicationStatus(userId);
  }

  /// Check supplier application verification status ('pending', 'verified', 'rejected', or null)
  Future<String?> getSupplierApplicationStatus(String userId) {
    return _authRepository.getSupplierApplicationStatus(userId);
  }

  /// Sign out current user session
  Future<void> signOut() async {
    try {
      emit(const AuthLoading());
      await _authRepository.signOut();
    } catch (_) {
      // Even if network fails during remote signout, clear local session
    } finally {
      emit(const Unauthenticated());
    }
  }

  /// Convenience alias for [signOut]
  Future<void> logout() => signOut();

  /// Clears any active error state back to [Unauthenticated] or current user
  void clearError() {
    if (state is AuthError) {
      emit(const Unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
