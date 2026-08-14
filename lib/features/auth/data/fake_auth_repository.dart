import 'dart:async';
import 'package:zim_herbs_repo/features/auth/domain/auth_repository.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';

class FakeAuthRepository implements AuthRepository {
  // Preset demo users
  static const UserModel fakeAdminUser = UserModel(
    id: 'admin-001',
    name: 'Zim Herbs Administrator',
    email: 'admin@zimherbs.co.zw',
    role: UserRole.admin,
    avatarUrl: 'https://i.pravatar.cc/150?img=60',
  );

  static const UserModel fakeCustomerUser = UserModel(
    id: 'cust-001',
    name: 'Tinashe Moyo',
    email: 'tinashe@zimherbs.co.zw',
    role: UserRole.customer,
    avatarUrl: 'https://i.pravatar.cc/150?img=32',
  );

  UserModel? _currentUser;
  final StreamController<UserModel?> _controller = StreamController<UserModel?>.broadcast();

  FakeAuthRepository({UserModel? initialUser}) : _currentUser = initialUser {
    // Emit initial state on stream initialization
    scheduleMicrotask(() => _controller.add(_currentUser));
  }

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentUser;
  }

  @override
  Future<UserModel> signInWithCredentials({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.contains('admin')) {
      _currentUser = fakeAdminUser.copyWith(email: cleanEmail);
    } else {
      _currentUser = fakeCustomerUser.copyWith(email: cleanEmail);
    }

    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserModel> signInWithFakeRole(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = role == UserRole.admin ? fakeAdminUser : fakeCustomerUser;
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
