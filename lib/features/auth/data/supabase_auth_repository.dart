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
  }) async {
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: fullName != null && fullName.trim().isNotEmpty
          ? {'full_name': fullName.trim()}
          : null,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Failed to create account with Supabase');
    }

    final userModel = await _fetchUserProfile(user);
    _authStateController.add(userModel);
    return userModel;
  }

  @override
  Future<void> signOut() async {
    await client.auth.signOut();
    _authStateController.add(null);
  }

  Future<UserModel> _fetchUserProfile(User user) async {
    try {
      final profile = await client
          .from('user_profiles')
          .select('id, email, full_name, is_admin, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        final isAdmin = profile['is_admin'] as bool? ?? false;
        final fullName = profile['full_name'] as String?;

        return UserModel(
          id: user.id,
          name: (fullName != null && fullName.trim().isNotEmpty)
              ? fullName.trim()
              : (user.email ?? 'User'),
          email: user.email ?? (profile['email'] as String? ?? ''),
          role: isAdmin ? UserRole.admin : UserRole.customer,
          avatarUrl: profile['avatar_url'] as String?,
        );
      }
    } catch (_) {
      // Fallback if user_profiles query fails
    }

    return UserModel(
      id: user.id,
      name: user.email?.split('@').first ?? 'User',
      email: user.email ?? '',
      role: UserRole.customer,
    );
  }

  void dispose() {
    _supabaseAuthSubscription?.cancel();
    _authStateController.close();
  }
}
