import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/domain/auth_repository.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';
import 'package:zim_herbs_repo/features/auth/presentation/login_page.dart';
import 'package:zim_herbs_repo/features/auth/presentation/portal_selection_page.dart';

class MockAuthRepo implements AuthRepository {
  @override
  Stream<UserModel?> get authStateChanges => const Stream.empty();
  @override
  Future<UserModel?> getCurrentUser() async => null;
  @override
  Future<UserModel> signInWithCredentials({required String email, required String password}) async =>
      const UserModel(id: '1', name: 'Test', email: 'test@example.com', role: UserRole.admin);
  @override
  Future<UserModel> signUpWithCredentials({required String email, required String password, String? fullName}) async =>
      const UserModel(id: '1', name: 'Test', email: 'test@example.com', role: UserRole.customer);
  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('LoginPage small mobile screen test (width: 320)', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final cubit = AuthCubit(MockAuthRepo());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: cubit,
          child: const LoginPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Toggle customer vs admin
    final adminTab = find.text('Admin');
    expect(adminTab, findsOneWidget);
    await tester.tap(adminTab);
    await tester.pumpAndSettle();

    final customerTab = find.text('Customer');
    expect(customerTab, findsOneWidget);
    await tester.tap(customerTab);
    await tester.pumpAndSettle();
  });

  testWidgets('PortalSelectionPage small mobile screen test (width: 320)', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final cubit = AuthCubit(MockAuthRepo());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: cubit,
          child: const PortalSelectionPage(
            user: UserModel(
              id: '1',
              name: 'Admin User',
              email: 'admin@example.com',
              role: UserRole.admin,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  });

  testWidgets('LoginPage standard mobile screen test (width: 390)', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final cubit = AuthCubit(MockAuthRepo());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: cubit,
          child: const LoginPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final adminTab = find.text('Admin Console');
    expect(adminTab, findsOneWidget);
    await tester.tap(adminTab);
    await tester.pumpAndSettle();

    final customerTab = find.text('Customer / Learn');
    expect(customerTab, findsOneWidget);
    await tester.tap(customerTab);
    await tester.pumpAndSettle();
  });

  testWidgets('PortalSelectionPage standard mobile screen test (width: 390)', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final cubit = AuthCubit(MockAuthRepo());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: cubit,
          child: const PortalSelectionPage(
            user: UserModel(
              id: '1',
              name: 'Admin User',
              email: 'admin@example.com',
              role: UserRole.admin,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  });
}
