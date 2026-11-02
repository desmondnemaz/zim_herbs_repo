import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/auth/domain/auth_repository.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';

/// Simulates SupabaseAuthRepository re-emitting the user after a Realtime
/// push on the signed-in user's `user_profiles` row.
class _PushingAuthRepository implements AuthRepository {
  _PushingAuthRepository(this.currentUser);

  final StreamController<UserModel?> _controller =
      StreamController<UserModel?>.broadcast();
  UserModel? currentUser;

  void pushServerUpdate(UserModel? user) {
    currentUser = user;
    _controller.add(user);
  }

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  Future<UserModel?> getCurrentUser() async => currentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const admin = UserModel(
    id: 'u1',
    name: 'Lawrence',
    email: 'l@test.com',
    role: UserRole.admin,
    isAdmin: true,
    isModerator: true,
  );

  test('admin revoked remotely is applied without re-login (keeps moderator)',
      () async {
    final repo = _PushingAuthRepository(admin);
    final cubit = AuthCubit(repo);
    await cubit.checkAuth();
    expect((cubit.state as Authenticated).user.canManageUsers, isTrue);

    repo.pushServerUpdate(UserModel.fromJson(const {
      'id': 'u1',
      'full_name': 'Lawrence',
      'email': 'l@test.com',
      'is_admin': false,
      'is_moderator': true,
    }));
    await Future<void>.delayed(Duration.zero);

    final user = (cubit.state as Authenticated).user;
    expect(user.canManageUsers, isFalse);
    expect(user.canModerate, isTrue);
    await cubit.close();
  });

  test('admin and moderator both revoked remotely removes moderation access',
      () async {
    final repo = _PushingAuthRepository(admin);
    final cubit = AuthCubit(repo);
    await cubit.checkAuth();

    repo.pushServerUpdate(UserModel.fromJson(const {
      'id': 'u1',
      'full_name': 'Lawrence',
      'email': 'l@test.com',
      'is_admin': false,
      'is_moderator': false,
    }));
    await Future<void>.delayed(Duration.zero);

    final user = (cubit.state as Authenticated).user;
    expect(user.canManageUsers, isFalse);
    expect(user.canModerate, isFalse);
    await cubit.close();
  });
}
