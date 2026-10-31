import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/components/herb_review_card.dart';
import 'package:zim_herbs_repo/core/components/public_herb_card.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/repositories/herb_repository.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/cubit/herb_cubit.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/pages/herbs_list.dart';

import 'package:zim_herbs_repo/features/settings/bloc/settings_cubit.dart';
import 'package:zim_herbs_repo/features/settings/data/repository/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  @override
  Future<double> getFontScale() async => 1.0;
  @override
  Future<void> saveFontScale(double scale) async {}
}

class FakeHerbRepository implements HerbRepository {
  final List<Herb> _herbs;
  FakeHerbRepository(this._herbs);

  @override
  Future<List<Herb>> getAllHerbs() async => _herbs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  FakeAuthCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const learnerId = 'learner-user-123';
  const otherUserId = 'other-user-456';

  final publishedHerb = Herb(
    id: 'h1',
    nameEn: 'Zumbani Published',
    validationStatus: RecordValidationStatus.published,
    isApproved: true,
    createdBy: otherUserId,
  );

  final learnerPendingHerb = Herb(
    id: 'h2',
    nameEn: 'My Draft Herb',
    validationStatus: RecordValidationStatus.submitted,
    isApproved: false,
    createdBy: learnerId,
  );

  final otherUserPendingHerb = Herb(
    id: 'h3',
    nameEn: 'Other User Draft',
    validationStatus: RecordValidationStatus.submitted,
    isApproved: false,
    createdBy: otherUserId,
  );

  final learnerPublishedHerb = Herb(
    id: 'h4',
    nameEn: 'My Approved Herb',
    validationStatus: RecordValidationStatus.published,
    isApproved: true,
    createdBy: learnerId,
  );

  group('HerbReviewCard Learner Creation Tests', () {
    testWidgets('Renders "My Creation" and "Pending Review" chip on learner unapproved herb', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HerbReviewCard(
              herb: learnerPendingHerb,
              currentUserId: learnerId,
              showStatusChip: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('My Draft Herb'), findsOneWidget);
      expect(find.text('My Creation'), findsOneWidget);
      expect(find.text('Pending Review'), findsOneWidget);
    });

    testWidgets('Renders "My Creation" and "Published" chip on learner approved herb', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HerbReviewCard(
              herb: learnerPublishedHerb,
              currentUserId: learnerId,
              showStatusChip: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('My Approved Herb'), findsOneWidget);
      expect(find.text('My Creation'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
    });

    testWidgets('Does not render status chips or "My Creation" when herb belongs to someone else on learner side', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HerbReviewCard(
              herb: publishedHerb,
              currentUserId: learnerId,
              showStatusChip: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Zumbani Published'), findsOneWidget);
      expect(find.text('My Creation'), findsNothing);
      expect(find.text('Published'), findsNothing);
      expect(find.text('Pending Review'), findsNothing);
    });
  });

  group('HerbsList Learner Visibility and Creator Filter Tests', () {
    testWidgets('Learner sees creator-only Pending Review and Published filter chips and cards', (tester) async {
      final fakeRepo = FakeHerbRepository([
        publishedHerb,
        learnerPendingHerb,
        learnerPublishedHerb,
        otherUserPendingHerb,
      ]);

      const learnerUser = UserModel(
        id: learnerId,
        name: 'Learner Tendai',
        email: 'tendai@example.com',
        role: UserRole.customer,
      );

      final fakeAuthCubit = FakeAuthCubit(const Authenticated(learnerUser));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>(create: (_) => SettingsCubit(FakeSettingsRepository())),
            BlocProvider<AuthCubit>.value(value: fakeAuthCubit),
            BlocProvider<HerbCubit>(create: (_) => HerbCubit(fakeRepo)),
          ],
          child: const MaterialApp(
            home: HerbsList(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Initial "All" view contains catalog herbs + learner's pending herb
      expect(find.text('Zumbani Published'), findsOneWidget);
      expect(find.text('My Approved Herb'), findsOneWidget);
      expect(find.text('My Draft Herb'), findsOneWidget);
      expect(find.text('Other User Draft'), findsNothing);

      // 2. Filter bar counts:
      // All: 3 (publishedHerb + learnerPendingHerb + learnerPublishedHerb)
      expect(find.text('All (3)'), findsOneWidget);
      // My Creations: 2 (learnerPendingHerb + learnerPublishedHerb)
      expect(find.text('My Creations (2)'), findsOneWidget);
      // Published on learner side: 1 (creator's only published herb)
      expect(find.text('Published (1)'), findsOneWidget);
      // Pending Review on learner side: 1 (creator's only pending herb)
      expect(find.text('Pending Review (1)'), findsOneWidget);

      // 3. Tap "Pending Review (1)" filter chip -> filters to creator's pending herbs only
      await tester.tap(find.text('Pending Review (1)'));
      await tester.pumpAndSettle();

      expect(find.text('My Draft Herb'), findsOneWidget);
      expect(find.text('My Approved Herb'), findsNothing);
      expect(find.text('Zumbani Published'), findsNothing);

      // 4. Tap "Published (1)" filter chip -> filters to creator's published herbs only
      await tester.tap(find.text('Published (1)'));
      await tester.pumpAndSettle();

      expect(find.text('My Approved Herb'), findsOneWidget);
      expect(find.text('My Draft Herb'), findsNothing);
      expect(find.text('Zumbani Published'), findsNothing);
    });

    testWidgets('Public app side removes marking logic (no Mark / Select toolbar or checkboxes)', (tester) async {
      final fakeRepo = FakeHerbRepository([
        publishedHerb,
        learnerPendingHerb,
        learnerPublishedHerb,
      ]);

      const learnerUser = UserModel(
        id: learnerId,
        name: 'Learner Tendai',
        email: 'tendai@example.com',
        role: UserRole.customer,
      );

      final fakeAuthCubit = FakeAuthCubit(const Authenticated(learnerUser));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>(create: (_) => SettingsCubit(FakeSettingsRepository())),
            BlocProvider<AuthCubit>.value(value: fakeAuthCubit),
            BlocProvider<HerbCubit>(create: (_) => HerbCubit(fakeRepo)),
          ],
          child: const MaterialApp(
            home: HerbsList(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify "Mark / Select" toolbar is NOT rendered on public side
      expect(find.text('Mark / Select'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);

      // 2. Long press on herb card does NOT enter selection mode for public learner
      await tester.longPress(find.text('Zumbani Published'));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('Staff side retains marking logic toolbar for batch management', (tester) async {
      final fakeRepo = FakeHerbRepository([
        publishedHerb,
        learnerPendingHerb,
        learnerPublishedHerb,
      ]);

      const staffUser = UserModel(
        id: 'staff-user-999',
        name: 'Moderator Chipo',
        email: 'chipo@example.com',
        role: UserRole.admin,
      );

      final fakeAuthCubit = FakeAuthCubit(const Authenticated(staffUser));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>(create: (_) => SettingsCubit(FakeSettingsRepository())),
            BlocProvider<AuthCubit>.value(value: fakeAuthCubit),
            BlocProvider<HerbCubit>(create: (_) => HerbCubit(fakeRepo)),
          ],
          child: const MaterialApp(
            home: HerbsList(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify "Mark / Select" toolbar is rendered for staff
      expect(find.text('Mark / Select'), findsOneWidget);
    });
  });

  group('HerbsList Admin Console Tests', () {
    const adminId = 'admin-user-777';
    const adminUser = UserModel(
      id: adminId,
      name: 'Admin Rudo',
      email: 'rudo@example.com',
      role: UserRole.admin,
    );

    final adminOwnHerb = Herb(
      id: 'h5',
      nameEn: 'Admin Own Herb',
      validationStatus: RecordValidationStatus.submitted,
      isApproved: false,
      createdBy: adminId,
    );

    Future<void> pumpAdminList(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakeHerbRepository([
        publishedHerb,
        otherUserPendingHerb,
        adminOwnHerb,
      ]);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>(create: (_) => SettingsCubit(FakeSettingsRepository())),
            BlocProvider<AuthCubit>.value(value: FakeAuthCubit(const Authenticated(adminUser))),
            BlocProvider<HerbCubit>(create: (_) => HerbCubit(fakeRepo)),
          ],
          child: const MaterialApp(home: HerbsList()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Shows All / Published / Pending filter chips and no My Creations', (tester) async {
      await pumpAdminList(tester);

      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Published (1)'), findsOneWidget);
      expect(find.text('Pending Review (2)'), findsOneWidget);
      expect(find.textContaining('My Creations'), findsNothing);
      // Admin's own herb is not tagged as "My Creation" in the admin console.
      expect(find.text('My Creation'), findsNothing);
    });

    testWidgets('Mark / Select enters selection mode and Select All marks visible herbs', (tester) async {
      await pumpAdminList(tester);

      await tester.tap(find.text('Mark / Select'));
      await tester.pumpAndSettle();

      expect(find.text('0 marked'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(3));

      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();
      expect(find.text('3 marked'), findsOneWidget);
      expect(find.text('Delete (3)'), findsOneWidget);

      // Switching filter clears marks so hidden herbs can't be deleted by accident.
      await tester.tap(find.text('Published (1)'));
      await tester.pumpAndSettle();
      expect(find.text('0 marked'), findsOneWidget);

      // Cancel exits selection mode.
      await tester.tap(find.byTooltip('Cancel selection'));
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Mark / Select'), findsOneWidget);
    });

    testWidgets('Long press on a herb enters selection mode with that herb marked', (tester) async {
      await pumpAdminList(tester);

      await tester.longPress(find.text('Zumbani Published'));
      await tester.pumpAndSettle();

      expect(find.text('1 marked'), findsOneWidget);
    });
  });

  group('HerbsList Public Catalog Tests', () {
    testWidgets('Public view renders PublicHerbCard and strictly hides admin controls even for admin user', (tester) async {
      final fakeHerbs = [publishedHerb, learnerPendingHerb];
      final fakeRepo = FakeHerbRepository(fakeHerbs);

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
            BlocProvider<HerbCubit>(
              create: (_) => HerbCubit(fakeRepo)..loadHerbs(),
            ),
          ],
          child: const MaterialApp(
            home: HerbsList(isPublicView: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only published herbs are visible to the public catalog
      expect(find.byType(PublicHerbCard), findsOneWidget);
      expect(find.byType(HerbReviewCard), findsNothing);

      // Verify zero admin options: NO 3-dots popup, NO checkboxes, NO toolbar, NO FAB
      expect(find.byType(PopupMenuButton), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Mark / Select'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('View Details'), findsOneWidget);
    });
  });
}

