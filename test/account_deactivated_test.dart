import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/domain/auth_repository.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';
import 'package:zim_herbs_repo/features/auth/presentation/account_deactivated_page.dart';
import 'package:zim_herbs_repo/features/auth/presentation/auth_gate.dart';

class _MockAuthRepo implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final StreamController<UserModel?> _controller = StreamController<UserModel?>.broadcast();
  UserModel? currentUser;

  _MockAuthRepo({this.currentUser});

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  Future<UserModel?> getCurrentUser() async => currentUser;

  @override
  Future<void> signOut() async {
    currentUser = null;
    _controller.add(null);
  }
}

void main() {
  group('UserModel isActive property', () {
    test('defaults isActive to true when not specified', () {
      const user = UserModel(
        id: 'u1',
        name: 'Tendai Moyo',
        email: 'tendai@example.com',
        role: UserRole.customer,
      );
      expect(user.isActive, isTrue);
    });

    test('correctly parses is_active from json', () {
      final activeJson = {
        'id': 'u2',
        'full_name': 'Chipo Sibanda',
        'email': 'chipo@example.com',
        'is_active': true,
      };
      final activeUser = UserModel.fromJson(activeJson);
      expect(activeUser.isActive, isTrue);

      final inactiveJson = {
        'id': 'u3',
        'full_name': 'Kuda Zhou',
        'email': 'kuda@example.com',
        'is_active': false,
      };
      final inactiveUser = UserModel.fromJson(inactiveJson);
      expect(inactiveUser.isActive, isFalse);

      // Null fallback to true
      final fallbackJson = {
        'id': 'u4',
        'email': 'fallback@example.com',
      };
      final fallbackUser = UserModel.fromJson(fallbackJson);
      expect(fallbackUser.isActive, isTrue);
    });

    test('serializes is_active to json', () {
      const inactiveUser = UserModel(
        id: 'u5',
        name: 'Deactivated User',
        email: 'deact@example.com',
        role: UserRole.customer,
        isActive: false,
      );
      final json = inactiveUser.toJson();
      expect(json['is_active'], isFalse);
    });

    test('copyWith properly updates isActive', () {
      const user = UserModel(
        id: 'u6',
        name: 'Test',
        email: 'test@example.com',
        role: UserRole.customer,
        isActive: true,
      );
      final updated = user.copyWith(isActive: false);
      expect(updated.isActive, isFalse);
      expect(updated.id, 'u6');
    });
  });

  group('AccountDeactivatedPage widget tests', () {
    testWidgets('renders account deactivated banner, user identity and options', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const user = UserModel(
        id: 'deact-1',
        name: 'Farai Dube',
        email: 'farai@zimherbs.co.zw',
        role: UserRole.customer,
        isPractitioner: true,
        isActive: false,
      );

      final mockRepo = _MockAuthRepo(currentUser: user);
      final authCubit = AuthCubit(mockRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: const AccountDeactivatedPage(user: user),
          ),
        ),
      );

      // Verify core UI elements
      expect(find.text('Account Deactivated'), findsOneWidget);
      expect(find.text('ACCOUNT SUSPENDED'), findsOneWidget);
      expect(find.text('Farai Dube'), findsOneWidget);
      expect(find.text('farai@zimherbs.co.zw'), findsOneWidget);
      expect(find.text('Contact Support / Appeal'), findsOneWidget);
      expect(find.text('Sign Out / Switch Account'), findsOneWidget);
    });

    testWidgets('Sign Out button triggers auth signOut', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const user = UserModel(
        id: 'deact-2',
        name: 'Tatenda Mutasa',
        email: 'tatenda@zimherbs.co.zw',
        role: UserRole.customer,
        isActive: false,
      );

      final mockRepo = _MockAuthRepo(currentUser: user);
      final authCubit = AuthCubit(mockRepo);
      await authCubit.checkAuth();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: const AccountDeactivatedPage(user: user),
          ),
        ),
      );

      // Tap Sign Out button
      final signOutBtn = find.text('Sign Out / Switch Account');
      expect(signOutBtn, findsOneWidget);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.currentUser, isNull);
    });
  });

  group('AuthGate deactivation routing', () {
    testWidgets('renders AccountDeactivatedPage when authenticated user is deactivated', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const deactivatedUser = UserModel(
        id: 'deact-3',
        name: 'Vimbai Moyo',
        email: 'vimbai@zimherbs.co.zw',
        role: UserRole.customer,
        isActive: false,
      );

      final mockRepo = _MockAuthRepo(currentUser: deactivatedUser);
      final authCubit = AuthCubit(mockRepo);
      await authCubit.checkAuth();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: const AuthGate(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show AccountDeactivatedPage
      expect(find.byType(AccountDeactivatedPage), findsOneWidget);
      expect(find.text('Account Deactivated'), findsOneWidget);
      expect(find.text('Vimbai Moyo'), findsOneWidget);
    });
  });
}
