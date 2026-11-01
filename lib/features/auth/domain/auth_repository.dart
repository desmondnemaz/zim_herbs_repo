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

  /// Sign up a new user using credentials and extended profile metadata
  Future<UserModel> signUpWithCredentials({
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
  });

  /// Update user profile metadata
  Future<UserModel> updateProfile(UserModel updatedUser);

  /// Apply for herbalist practitioner verification
  Future<void> applyForPractitioner({
    required String specialisation,
    required int yearsOfExperience,
    String? location,
    String? phoneNumber,
  });

  /// Apply for marketplace supplier status (queued for admin approval before publishing)
  Future<void> applyForSupplier({
    required String businessName,
    String? location,
    String? categories,
    int? yearsInOperation,
    String? contactPhone,
    String? bio,
    String? description,
  });

  /// Fetch practitioner application verification status ('pending', 'verified', 'rejected', or null)
  Future<String?> getPractitionerApplicationStatus(String userId);

  /// Fetch botanical supplier application verification status ('pending', 'verified', 'rejected', or null)
  Future<String?> getSupplierApplicationStatus(String userId) async => null;

  /// Sign out current user
  Future<void> signOut();
}
