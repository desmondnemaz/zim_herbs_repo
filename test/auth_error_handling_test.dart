import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:zim_herbs_repo/core/connection/bloc/connection_bloc.dart' as conn;
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/auth/domain/auth_repository.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';
import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/features/auth/presentation/login_page.dart';
import 'package:zim_herbs_repo/features/auth/presentation/auth_gate.dart';

class MockTestAuthRepository implements AuthRepository {
  final StreamController<UserModel?> _controller =
      StreamController<UserModel?>.broadcast();
  UserModel? currentUser;
  Object? errorToThrowOnSignIn;
  Object? errorToThrowOnSignUp;

  UserRole roleToReturn = UserRole.customer;

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  Future<UserModel?> getCurrentUser() async => currentUser;

  @override
  Future<UserModel> signInWithCredentials(
      {required String email, required String password}) async {
    if (errorToThrowOnSignIn != null) {
      throw errorToThrowOnSignIn!;
    }
    currentUser = UserModel(
      id: '1',
      name: 'Test Customer',
      email: email,
      role: roleToReturn,
    );
    _controller.add(currentUser);
    return currentUser!;
  }

  @override
  Future<UserModel> signUpWithCredentials(
      {required String email,
      required String password,
      String? fullName}) async {
    if (errorToThrowOnSignUp != null) {
      throw errorToThrowOnSignUp!;
    }
    currentUser = UserModel(
      id: '2',
      name: fullName ?? 'Test Customer',
      email: email,
      role: UserRole.customer,
    );
    _controller.add(currentUser);
    return currentUser!;
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
    _controller.add(null);
  }
}

void main() {
  group('ErrorHandler unit tests', () {
    test('maps invalid login credentials AuthException to FailureType.invalidCredentials', () {
      const authEx = AuthException('Invalid login credentials', statusCode: '400');
      final failure = ErrorHandler.handle(authEx);

      expect(failure.type, FailureType.invalidCredentials);
      expect(failure.title, 'Incorrect Credentials');
      expect(failure.message, contains('email or password you entered is incorrect'));
    });

    test('maps user already registered AuthException to FailureType.userAlreadyExists', () {
      const authEx = AuthException('User already registered', statusCode: '422');
      final failure = ErrorHandler.handle(authEx);

      expect(failure.type, FailureType.userAlreadyExists);
      expect(failure.title, 'Account Already Exists');
      expect(failure.message, contains('already exists'));
    });

    test('maps weak password AuthException to FailureType.weakPassword', () {
      const authEx = AuthException('Password should be at least 6 characters', statusCode: '422');
      final failure = ErrorHandler.handle(authEx);

      expect(failure.type, FailureType.weakPassword);
      expect(failure.title, 'Weak Password');
      expect(failure.message, contains('at least 6 characters'));
    });

    test('maps server 502/503 AuthException to FailureType.serverUnavailable', () {
      const authEx = AuthException('Bad Gateway', statusCode: '502');
      final failure = ErrorHandler.handle(authEx);

      expect(failure.type, FailureType.serverUnavailable);
      expect(failure.title, 'Server Unavailable');
      expect(failure.message, contains('temporarily down'));
    });

    test('maps SocketException to FailureType.noInternet', () {
      const socketEx = SocketException('Failed host lookup: x.supabase.co');
      final failure = ErrorHandler.handle(socketEx);

      expect(failure.type, FailureType.noInternet);
      expect(failure.title, 'No Internet Connection');
      expect(failure.message, contains('Wi-Fi or mobile data'));
    });

    test('maps TimeoutException to FailureType.timeout', () {
      final timeoutEx = TimeoutException('Future not completed');
      final failure = ErrorHandler.handle(timeoutEx);

      expect(failure.type, FailureType.timeout);
      expect(failure.title, 'Connection Timed Out');
    });

    test('maps client network string errors cleanly', () {
      final error = Exception('ClientException with SocketException: Failed host lookup: ...');
      final failure = ErrorHandler.handle(error);

      expect(failure.type, FailureType.noInternet);
      expect(failure.title, 'No Internet Connection');
    });
  });

  group('AuthCubit error handling tests', () {
    late MockTestAuthRepository mockRepo;
    late AuthCubit cubit;

    setUp(() {
      mockRepo = MockTestAuthRepository();
      cubit = AuthCubit(mockRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('emits AuthError with friendly Failure when credentials fail', () async {
      mockRepo.errorToThrowOnSignIn =
          const AuthException('Invalid login credentials', statusCode: '400');

      await cubit.signInWithCredentials(
        email: 'wrong@example.com',
        password: 'wrongpassword',
      );

      expect(cubit.state, isA<AuthError>());
      final errorState = cubit.state as AuthError;
      expect(errorState.failure?.type, FailureType.invalidCredentials);
      expect(errorState.message, contains('email or password you entered is incorrect'));
    });

    test('emits AuthError with noInternet Failure when network is unreachable', () async {
      mockRepo.errorToThrowOnSignIn =
          const SocketException('Network is unreachable');

      await cubit.signInWithCredentials(
        email: 'user@example.com',
        password: 'password123',
      );

      expect(cubit.state, isA<AuthError>());
      final errorState = cubit.state as AuthError;
      expect(errorState.failure?.type, FailureType.noInternet);
      expect(errorState.failure?.title, 'No Internet Connection');
    });

    test('emits accessDenied AuthError when non-admin attempts admin sign-in', () async {
      mockRepo.errorToThrowOnSignIn = null;

      await cubit.signInWithCredentials(
        email: 'customer@example.com',
        password: 'password123',
        requireAdmin: true,
      );

      expect(cubit.state, isA<AuthError>());
      final errorState = cubit.state as AuthError;
      expect(errorState.failure?.type, FailureType.accessDenied);
      expect(errorState.message, contains('administrator privileges'));
    });

    test('clearError resets state from AuthError to Unauthenticated', () async {
      mockRepo.errorToThrowOnSignIn =
          const AuthException('Invalid login credentials', statusCode: '400');

      await cubit.signInWithCredentials(
        email: 'wrong@example.com',
        password: 'wrongpassword',
      );
      expect(cubit.state, isA<AuthError>());

      cubit.clearError();
      expect(cubit.state, isA<Unauthenticated>());
    });
  });

  group('LoginPage validation tests', () {
    testWidgets('shows validation errors for invalid email format', (tester) async {
      final mockRepo = MockTestAuthRepository();
      final authCubit = AuthCubit(mockRepo);
      final connBloc = conn.ConnectionBloc();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<conn.ConnectionBloc>.value(value: connBloc),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Tap Sign In without filling email
      final signInBtn = find.text('Sign In as Learner');
      expect(signInBtn, findsOneWidget);

      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      // Enter invalid email format
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address (e.g. name@example.com)'), findsOneWidget);

      authCubit.close();
      connBloc.close();
    });

    testWidgets('shows confirm password field and validation in sign up mode', (tester) async {
      final mockRepo = MockTestAuthRepository();
      final authCubit = AuthCubit(mockRepo);
      final connBloc = conn.ConnectionBloc();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<conn.ConnectionBloc>.value(value: connBloc),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Switch to Create Account
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      authCubit.close();
      connBloc.close();
    });

    testWidgets('shows Login Unsuccessful feedback on AuthError', (tester) async {
      final mockRepo = MockTestAuthRepository();
      mockRepo.errorToThrowOnSignIn =
          const AuthException('Invalid login credentials', statusCode: '400');
      final authCubit = AuthCubit(mockRepo);
      final connBloc = conn.ConnectionBloc();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<conn.ConnectionBloc>.value(value: connBloc),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'wrongpassword');

      final signInBtn = find.text('Sign In as Learner');
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      // Inline banner should be displayed
      expect(find.byType(AppErrorView), findsOneWidget);
      // Inline banner with title should be shown
      expect(find.text('Incorrect Credentials'), findsWidgets);

      authCubit.close();
      connBloc.close();
    });

    testWidgets('shows Login successful banner when authenticated via AuthGate', (tester) async {
      final mockRepo = MockTestAuthRepository();
      mockRepo.roleToReturn = UserRole.admin;
      final authCubit = AuthCubit(mockRepo);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
          ],
          child: const MaterialApp(
            home: AuthGate(),
          ),
        ),
      );

      await tester.pump();

      // Sign in with credentials
      await authCubit.signInWithCredentials(
        email: 'customer@example.com',
        password: 'password123',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Login successful! Welcome'), findsOneWidget);

      authCubit.close();
    });
  });
}
