import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/auth/domain/auth_repository.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';
import 'package:zim_herbs_repo/features/auth/presentation/auth_gate.dart';
import 'package:zim_herbs_repo/features/auth/presentation/login_page.dart';

class FakeAuthRepository implements AuthRepository {
  final StreamController<UserModel?> _controller = StreamController<UserModel?>.broadcast();
  UserModel? currentUser;
  bool shouldThrowOnSignOut = false;

  FakeAuthRepository({this.currentUser});

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  Future<UserModel?> getCurrentUser() async => currentUser;

  @override
  Future<UserModel> signInWithCredentials({required String email, required String password}) async {
    currentUser = const UserModel(id: '1', name: 'Admin', email: 'admin@test.com', role: UserRole.admin);
    _controller.add(currentUser);
    return currentUser!;
  }

  @override
  Future<UserModel> signUpWithCredentials({required String email, required String password, String? fullName}) async {
    currentUser = const UserModel(id: '2', name: 'User', email: 'user@test.com', role: UserRole.customer);
    _controller.add(currentUser);
    return currentUser!;
  }

  @override
  Future<void> signOut() async {
    if (shouldThrowOnSignOut) {
      throw Exception('Network disconnected');
    }
    currentUser = null;
    _controller.add(null);
  }
}

void main() {
  test('AuthCubit signOut emits Unauthenticated successfully', () async {
    final repo = FakeAuthRepository(
      currentUser: const UserModel(id: '1', name: 'Admin', email: 'admin@test.com', role: UserRole.admin),
    );
    final cubit = AuthCubit(repo);
    await cubit.checkAuth();
    expect(cubit.state, isA<Authenticated>());

    await cubit.signOut();
    expect(cubit.state, isA<Unauthenticated>());
  });

  test('AuthCubit signOut emits Unauthenticated even when repository throws', () async {
    final repo = FakeAuthRepository(
      currentUser: const UserModel(id: '1', name: 'Admin', email: 'admin@test.com', role: UserRole.admin),
    );
    repo.shouldThrowOnSignOut = true;

    final cubit = AuthCubit(repo);
    await cubit.checkAuth();
    expect(cubit.state, isA<Authenticated>());

    await cubit.signOut();
    expect(cubit.state, isA<Unauthenticated>());
  });

  testWidgets('Sign out triggers navigation back to LoginPage', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    final repo = FakeAuthRepository(
      currentUser: const UserModel(id: '1', name: 'Admin User', email: 'admin@test.com', role: UserRole.admin),
    );
    final cubit = AuthCubit(repo);
    await cubit.checkAuth();

    bool wasAuthenticated = true;

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) {
            if (current is Authenticated) {
              wasAuthenticated = true;
            }
            return current is Unauthenticated && wasAuthenticated;
          },
          listener: (context, state) {
            wasAuthenticated = false;
            navKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthGate()),
              (route) => false,
            );
          },
          child: MaterialApp(
            navigatorKey: navKey,
            home: const AuthGate(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify PortalSelectionPage is shown for authenticated admin
    expect(find.text('Welcome, Admin User!'), findsOneWidget);

    // Tap the sign out button
    final signOutBtn = find.byTooltip('Sign Out');
    expect(signOutBtn, findsOneWidget);
    await tester.tap(signOutBtn);

    await tester.pumpAndSettle();

    // Verify it navigated to LoginPage
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
