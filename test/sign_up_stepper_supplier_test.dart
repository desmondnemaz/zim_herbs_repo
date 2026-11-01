import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/domain/auth_repository.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';
import 'package:zim_herbs_repo/features/auth/presentation/sign_up_stepper_page.dart';

class MockSupplierAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final StreamController<UserModel?> _controller =
      StreamController<UserModel?>.broadcast();

  String? lastSupplierName;
  String? lastSupplierLocation;
  String? lastPrimaryRole;

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  Future<UserModel?> getCurrentUser() async => null;

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
    lastSupplierName = supplierName;
    lastSupplierLocation = supplierLocation;
    lastPrimaryRole = primaryRole;

    final user = UserModel(
      id: 'mock-supplier-id',
      email: email,
      name: fullName ?? 'Supplier Owner',
      role: UserRole.customer,
      primaryRole: primaryRole ?? 'supplier',
      isSupplier: false, // Remains pending until approved
    );
    _controller.add(user);
    return user;
  }
}

void main() {
  testWidgets('SignUpStepperPage displays Supplier Accreditation step when supplier persona is selected', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = MockSupplierAuthRepository();
    final authCubit = AuthCubit(mockRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const SignUpStepperPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial Step 1: Account
    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Account Credentials'), findsOneWidget);

    // Fill Step 1 (Email, Username, Password, Confirm Password)
    await tester.enterText(find.byType(TextFormField).at(0), 'supplier@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'tmutasa');
    await tester.enterText(find.byType(TextFormField).at(2), 'Secret123!');
    await tester.enterText(find.byType(TextFormField).at(3), 'Secret123!');
    await tester.pumpAndSettle();

    // Click "Continue" to Step 2
    final continueBtn = find.widgetWithText(ElevatedButton, 'Continue');
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    // Verify Step 2: Personal & Contact (Full Name, Phone, Location)
    expect(find.text('Personal Details'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Tendai Mutasa');
    await tester.enterText(find.byType(TextFormField).at(1), '+263771999888');
    await tester.enterText(find.byType(TextFormField).at(2), 'Harare, Zimbabwe');
    await tester.pumpAndSettle();

    // Click "Continue" to Step 3
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    // Verify Step 3: Persona Selection
    expect(find.text('Botanical Supplier / Vendor'), findsOneWidget);

    // Select Supplier Role
    final supplierCard = find.text('Botanical Supplier / Vendor');
    await tester.ensureVisible(supplierCard);
    await tester.tap(supplierCard);
    await tester.pumpAndSettle();

    // Accreditation title appears in stepper header when supplier is selected
    expect(find.text('Accreditation'), findsOneWidget);

    // Click "Continue" to Step 4
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    // Verify Step 4: Supplier Registration accreditation form
    expect(find.text('Supplier Registration'), findsOneWidget);
    expect(find.textContaining('Your supplier application will be queued for administrator review'), findsOneWidget);

    // Fill Step 4 Supplier Form
    await tester.enterText(find.byType(TextFormField).at(0), 'Mutasa Botanical Organics');
    await tester.enterText(find.byType(TextFormField).at(1), 'Moringa, Baobab, Lippia Javanica');
    await tester.enterText(find.byType(TextFormField).at(2), '4');
    await tester.pumpAndSettle();

    // Tap "Complete Registration"
    final submitBtn = find.text('Complete Registration');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Verify that signUpWithCredentials was called with supplier parameters!
    expect(mockRepo.lastPrimaryRole, equals('supplier'));
    expect(mockRepo.lastSupplierName, equals('Mutasa Botanical Organics'));
    expect(mockRepo.lastSupplierLocation, equals('Harare, Zimbabwe'));
  });
}
