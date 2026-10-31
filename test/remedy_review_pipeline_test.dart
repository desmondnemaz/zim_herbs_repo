import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/components/public_remedy_card.dart';
import 'package:zim_herbs_repo/core/components/remedy_review_card.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/datasources/condition_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/models/condition_model.dart';
import 'package:zim_herbs_repo/features/repository/remedies/domain/entities/remedy.dart';
import 'package:zim_herbs_repo/features/repository/remedies/domain/repositories/remedy_repository.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/pages/remedies_list.dart';
import 'package:zim_herbs_repo/features/settings/bloc/settings_cubit.dart';
import 'package:zim_herbs_repo/features/settings/data/repository/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  @override
  Future<double> getFontScale() async => 1.0;
  @override
  Future<void> saveFontScale(double scale) async {}
}

class FakeRemedyRepository implements RemedyRepository {
  final List<Remedy> _remedies;
  final List<String> deletedIds = [];
  final Map<String, bool> approvedStatus = {};

  FakeRemedyRepository(this._remedies);

  @override
  Future<List<Remedy>> getAllRemedies() async => _remedies;

  @override
  Future<void> deleteRemedy(String id) async {
    deletedIds.add(id);
    _remedies.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> deleteRemedies(List<String> ids) async {
    deletedIds.addAll(ids);
    _remedies.removeWhere((r) => ids.contains(r.id));
  }

  @override
  Future<void> approveRemedy(
    String id, {
    bool approved = true,
    String? verifiedBy,
    String? moderationNotes,
  }) async {
    approvedStatus[id] = approved;
  }

  @override
  Future<void> updateRemedyVerification(
    String remedyId,
    bool isApproved, {
    String? verifiedBy,
    String? moderationNotes,
  }) async {
    approvedStatus[remedyId] = isApproved;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  FakeAuthCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeConditionRemoteDataSource implements ConditionRemoteDataSource {
  @override
  Future<List<ConditionModel>> getAllConditions() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const learnerId = 'learner-user-123';
  const otherUserId = 'other-user-456';

  final publishedRemedy = const Remedy(
    id: 'r1',
    name: 'Zumbani Cough Tonic',
    conditionId: 'c1',
    methodOfUse: 'Drink warm decoction',
    preparation: 'Boil leaves for 10 minutes',
    validationStatus: RecordValidationStatus.published,
    isApproved: true,
    createdBy: otherUserId,
  );

  final learnerPendingRemedy = const Remedy(
    id: 'r2',
    name: 'My Special Remedy',
    conditionId: 'c1',
    methodOfUse: 'Inhale steam',
    preparation: 'Steep in boiling water',
    validationStatus: RecordValidationStatus.submitted,
    isApproved: false,
    createdBy: learnerId,
  );

  final otherUserPendingRemedy = const Remedy(
    id: 'r3',
    name: 'Other User Draft Remedy',
    conditionId: 'c1',
    methodOfUse: 'Apply paste',
    preparation: 'Crush roots into poultice',
    validationStatus: RecordValidationStatus.submitted,
    isApproved: false,
    createdBy: otherUserId,
  );

  group('RemedyReviewCard Pipeline Tests', () {
    testWidgets('Renders "My Creation" and "Pending Review" chip on learner unapproved remedy',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemedyReviewCard(
              remedy: learnerPendingRemedy,
              currentUserId: learnerId,
              showStatusChip: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('My Special Remedy'), findsOneWidget);
      expect(find.text('My Creation'), findsOneWidget);
      expect(find.text('Pending Review'), findsOneWidget);
    });

    testWidgets('Renders selection checkbox and handles toggle in selection mode',
        (tester) async {
      bool? toggledValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemedyReviewCard(
              remedy: publishedRemedy,
              isSelectionMode: true,
              isSelected: false,
              onToggleSelect: (val) => toggledValue = val,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(toggledValue, isTrue);
    });

    testWidgets('Renders Reject Submission in popup menu and triggers callback',
        (tester) async {
      bool rejectCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemedyReviewCard(
              remedy: learnerPendingRemedy,
              onTap: () {},
              onReject: () => rejectCalled = true,
            ),
          ),
        ),
      );

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Reject'), findsOneWidget);
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      expect(rejectCalled, isTrue);
    });
  });

  group('RemediesList Review Pipeline Tests', () {
    testWidgets('Admin sees filter chips (All, Published, Pending Review)', (tester) async {
      final fakeRepo = FakeRemedyRepository([
        publishedRemedy,
        learnerPendingRemedy,
        otherUserPendingRemedy,
      ]);
      final fakeConditionDs = FakeConditionRemoteDataSource();

      const adminUser = UserModel(
        id: 'admin-1',
        name: 'Admin User',
        email: 'admin@zimherbs.co.zw',
        role: UserRole.admin,
        isAdmin: true,
      );

      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>(
              create: (_) => SettingsCubit(FakeSettingsRepository()),
            ),
            BlocProvider<AuthCubit>(
              create: (_) => FakeAuthCubit(const Authenticated(adminUser)),
            ),
          ],
          child: MaterialApp(
            home: RemediesList(
              repository: fakeRepo,
              conditionDataSource: fakeConditionDs,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Published (1)'), findsOneWidget);
      expect(find.text('Pending Review (2)'), findsOneWidget);
      // Admin should not see "My Creations" chip
      expect(find.textContaining('My Creations'), findsNothing);

      // Admin sees all 3 remedies
      expect(find.text('Zumbani Cough Tonic'), findsOneWidget);
      expect(find.text('My Special Remedy'), findsOneWidget);
      expect(find.text('Other User Draft Remedy'), findsOneWidget);
    });

    testWidgets('Learner sees published remedies and own creation, but not other users pending remedies',
        (tester) async {
      final fakeRepo = FakeRemedyRepository([
        publishedRemedy,
        learnerPendingRemedy,
        otherUserPendingRemedy,
      ]);
      final fakeConditionDs = FakeConditionRemoteDataSource();

      const learnerUser = UserModel(
        id: learnerId,
        name: 'Learner User',
        email: 'learner@zimherbs.co.zw',
        role: UserRole.customer,
      );

      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>(
              create: (_) => SettingsCubit(FakeSettingsRepository()),
            ),
            BlocProvider<AuthCubit>(
              create: (_) => FakeAuthCubit(const Authenticated(learnerUser)),
            ),
          ],
          child: MaterialApp(
            home: RemediesList(
              repository: fakeRepo,
              conditionDataSource: fakeConditionDs,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Learner sees "My Creations" chip
      expect(find.text('My Creations (1)'), findsOneWidget);

      // Learner sees published + own creation
      expect(find.text('Zumbani Cough Tonic'), findsOneWidget);
      expect(find.text('My Special Remedy'), findsOneWidget);

      // Other user draft MUST NOT be visible to learner
      expect(find.text('Other User Draft Remedy'), findsNothing);
    });

    testWidgets('Public view renders PublicRemedyCard and hides admin controls even for admin user', (tester) async {
      final fakeRepo = FakeRemedyRepository([publishedRemedy, learnerPendingRemedy]);
      final fakeConditionDs = FakeConditionRemoteDataSource();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(
              value: FakeAuthCubit(
                const Authenticated(
                  UserModel(
                    id: 'admin-1',
                    email: 'admin@zimherbs.co.zw',
                    name: 'Admin User',
                    role: UserRole.admin,
                  ),
                ),
              ),
            ),
            BlocProvider<SettingsCubit>(
              create: (_) => SettingsCubit(FakeSettingsRepository()),
            ),
          ],
          child: MaterialApp(
            home: RemediesList(
              repository: fakeRepo,
              conditionDataSource: fakeConditionDs,
              isPublicView: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Renders PublicRemedyCard and NOT RemedyReviewCard
      expect(find.byType(PublicRemedyCard), findsOneWidget);
      expect(find.byType(RemedyReviewCard), findsNothing);

      // Verify zero admin controls
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Mark / Select'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('View Remedy'), findsOneWidget);
    });
  });
}

