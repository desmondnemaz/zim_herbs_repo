import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/features/auth/domain/auth_repository.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';

/// Real implementation of [AuthRepository] powered by Supabase Auth and `user_profiles`.
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient client;

  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();

  StreamSubscription<AuthState>? _supabaseAuthSubscription;

  SupabaseAuthRepository(this.client) {
    _init();
  }

  void _init() {
    _supabaseAuthSubscription =
        client.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user != null) {
        final userModel = await _fetchUserProfile(user);
        _authStateController.add(userModel);
      } else {
        _authStateController.add(null);
      }
    });
  }

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return await _fetchUserProfile(user);
  }

  @override
  Future<UserModel> signInWithCredentials({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Failed to authenticate with Supabase');
    }

    final userModel = await _fetchUserProfile(user);
    _authStateController.add(userModel);
    return userModel;
  }

  @override
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
  }) async {
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        if (fullName != null && fullName.trim().isNotEmpty)
          'full_name': fullName.trim(),
        if (username != null && username.trim().isNotEmpty)
          'username': username.trim(),
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          'phone_number': phoneNumber.trim(),
        if (primaryRole != null) 'primary_role': primaryRole,
      },
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Failed to create account with Supabase');
    }

    // Upsert full profile metadata into user_profiles
    try {
      final effectiveUsername = (username != null && username.trim().isNotEmpty)
          ? username.trim()
          : email.trim().split('@').first;
      final effectiveName = (fullName != null && fullName.trim().isNotEmpty)
          ? fullName.trim()
          : effectiveUsername;

      await client.from('user_profiles').upsert({
        'id': user.id,
        'email': email.trim(),
        'full_name': effectiveName,
        'username': effectiveUsername,
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          'phone_number': phoneNumber.trim(),
        if (location != null && location.trim().isNotEmpty)
          'location': location.trim(),
        'primary_role': primaryRole ?? 'household',
        'is_practitioner': false,
        'is_supplier': false, // Requires admin review and verification before publishing
        'is_admin': false,
        'is_moderator': false,
        'health_interests': healthInterests ?? [],
        if (bio != null && bio.trim().isNotEmpty) 'bio': bio.trim(),
        'onboarding_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // If user also applied as a practitioner during signup, record application in herbalist_profiles
      if (practitionerSpecialisation != null &&
          practitionerSpecialisation.trim().isNotEmpty) {
        await client.from('herbalist_profiles').upsert({
          'id': user.id,
          'specialisation': practitionerSpecialisation.trim(),
          'years_of_experience': practitionerYearsOfExperience ?? 1,
          if (location != null && location.trim().isNotEmpty)
            'location': location.trim(),
          if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
            'phone_number': phoneNumber.trim(),
          'verification_status': 'pending',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // If user registered as a supplier during signup, record application in supplier_profiles
      final effectiveSupplierName = (supplierName != null && supplierName.trim().isNotEmpty)
          ? supplierName.trim()
          : (primaryRole == 'supplier' ? effectiveName : null);

      if (effectiveSupplierName != null) {
        final effectiveSupplierLocation = (supplierLocation != null && supplierLocation.trim().isNotEmpty)
            ? supplierLocation.trim()
            : (location != null && location.trim().isNotEmpty ? location.trim() : 'Zimbabwe');

        await client.from('supplier_profiles').upsert({
          'id': user.id,
          'supplier_name': effectiveSupplierName,
          'location': effectiveSupplierLocation,
          'verification_status': 'pending',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {
      // Continue even if profile enrichment encounters an RLS constraint
    }

    final userModel = await _fetchUserProfile(user);
    _authStateController.add(userModel);
    return userModel;
  }

  @override
  Future<UserModel> updateProfile(UserModel updatedUser) async {
    await client.from('user_profiles').update({
      'full_name': updatedUser.name,
      'username': updatedUser.username,
      'phone_number': updatedUser.phoneNumber,
      'location': updatedUser.location,
      'bio': updatedUser.bio,
      'health_interests': updatedUser.healthInterests,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', updatedUser.id);

    _authStateController.add(updatedUser);
    return updatedUser;
  }

  @override
  Future<void> applyForPractitioner({
    required String specialisation,
    required int yearsOfExperience,
    String? location,
    String? phoneNumber,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await client.from('herbalist_profiles').upsert({
      'id': user.id,
      'specialisation': specialisation.trim(),
      'years_of_experience': yearsOfExperience,
      if (location != null && location.trim().isNotEmpty)
        'location': location.trim(),
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
        'phone_number': phoneNumber.trim(),
      'verification_status': 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Also update primary_role if currently household
    await client.from('user_profiles').update({
      'primary_role': 'practitioner',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);

    final refreshed = await _fetchUserProfile(user);
    _authStateController.add(refreshed);
  }

  @override
  Future<void> applyForSupplier({
    required String businessName,
    String? location,
    String? categories,
    int? yearsInOperation,
    String? contactPhone,
    String? bio,
    String? description,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // 1. Record / upsert supplier application in supplier_profiles in pending status
    await client.from('supplier_profiles').upsert({
      'id': user.id,
      'supplier_name': businessName.trim(),
      if (location != null && location.trim().isNotEmpty)
        'location': location.trim(),
      'verification_status': 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    });

    // 2. Update user_profiles metadata (role, phone, bio) without setting is_supplier: true
    final effectiveBio = description ?? bio;
    await client.from('user_profiles').update({
      'primary_role': 'supplier',
      if (contactPhone != null && contactPhone.trim().isNotEmpty)
        'phone_number': contactPhone.trim(),
      if (location != null && location.trim().isNotEmpty)
        'location': location.trim(),
      if (effectiveBio != null && effectiveBio.trim().isNotEmpty)
        'bio': effectiveBio.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);

    final refreshed = await _fetchUserProfile(user);
    _authStateController.add(refreshed);
  }

  @override
  Future<String?> getPractitionerApplicationStatus(String userId) async {
    try {
      final res = await client
          .from('herbalist_profiles')
          .select('verification_status')
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        return res['verification_status'] as String?;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<String?> getSupplierApplicationStatus(String userId) async {
    try {
      final res = await client
          .from('supplier_profiles')
          .select('verification_status')
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        return res['verification_status'] as String?;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (_) {
      // Even if remote sign out fails (e.g. offline/network issue), ensure local sign out succeeds
    } finally {
      _authStateController.add(null);
    }
  }

  Future<UserModel> _fetchUserProfile(User user) async {
    try {
      final profile = await client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        final profileMap = Map<String, dynamic>.from(profile);
        profileMap['email'] = user.email ?? profileMap['email'];
        return UserModel.fromJson(profileMap);
      }
    } catch (_) {
      // Fallback if user_profiles query fails
    }

    return UserModel(
      id: user.id,
      name: user.email?.split('@').first ?? 'User',
      email: user.email ?? '',
      role: UserRole.customer,
      isAdmin: false,
      isModerator: false,
    );
  }

  void dispose() {
    _supabaseAuthSubscription?.cancel();
    _authStateController.close();
  }
}
