import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/pages/herbs_list.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/repositories/herb_repository.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/cubit/herb_cubit.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/condition_list.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/repositories/condition_repository.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/entities/condition.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/cubit/condition_cubit.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/pages/remedies_list.dart';
import 'package:zim_herbs_repo/features/repository/remedies/domain/repositories/remedy_repository.dart';
import 'package:zim_herbs_repo/features/repository/remedies/domain/entities/remedy.dart';
import 'package:zim_herbs_repo/features/marketplace/store/presentation/store_page.dart';
import 'package:zim_herbs_repo/features/marketplace/store/data/repository/store_repository.dart';
import 'package:zim_herbs_repo/features/marketplace/store/bloc/store_bloc.dart';
import 'package:zim_herbs_repo/features/marketplace/store/bloc/cart_cubit.dart';
import 'package:zim_herbs_repo/features/settings/bloc/settings_cubit.dart';
import 'package:zim_herbs_repo/features/settings/data/repository/settings_repository.dart';

class MockRemedyRepository implements RemedyRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getAllRemedies || invocation.memberName == #getRemedies) {
      return Future.value(<Remedy>[]);
    }
    return super.noSuchMethod(invocation);
  }
}

class MockHerbRepository implements HerbRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getAllHerbs || invocation.memberName == #getHerbs) {
      return Future.value(<Herb>[]);
    }
    return super.noSuchMethod(invocation);
  }
}

class MockConditionRepository implements ConditionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getAllConditions || invocation.memberName == #getConditions) {
      return Future.value(<Condition>[]);
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeSettingsRepository implements SettingsRepository {
  @override
  Future<double> getFontScale() async => 1.0;
  @override
  Future<void> saveFontScale(double scale) async {}
}

class FakeStoreRepository implements StoreRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future.value([]);
  }
}

void main() {
  testWidgets('HerbsList calls onBack callback when provided', (tester) async {
    bool onBackCalled = false;
    final herbRepo = MockHerbRepository();
    final settingsRepo = FakeSettingsRepository();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>(create: (_) => SettingsCubit(settingsRepo)),
          BlocProvider<HerbCubit>(create: (_) => HerbCubit(herbRepo)),
        ],
        child: MaterialApp(
          home: HerbsList(
            onBack: () {
              onBackCalled = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final backBtn = find.byIcon(Icons.arrow_back);
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(onBackCalled, isTrue);
  });

  testWidgets('ConditionsListPage calls onBack callback when provided', (tester) async {
    bool onBackCalled = false;
    final conditionRepo = MockConditionRepository();
    final settingsRepo = FakeSettingsRepository();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>(create: (_) => SettingsCubit(settingsRepo)),
          BlocProvider<ConditionCubit>(create: (_) => ConditionCubit(conditionRepo)),
        ],
        child: MaterialApp(
          home: ConditionsListPage(
            onBack: () {
              onBackCalled = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final backBtn = find.byIcon(Icons.arrow_back);
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(onBackCalled, isTrue);
  });

  testWidgets('RemediesList calls onBack callback when provided', (tester) async {
    bool onBackCalled = false;
    final settingsRepo = FakeSettingsRepository();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>(create: (_) => SettingsCubit(settingsRepo)),
        ],
        child: MaterialApp(
          home: RemediesList(
            repository: MockRemedyRepository(),
            onBack: () {
              onBackCalled = true;
            },
          ),
        ),
      ),
    );

    await tester.pump();

    final backBtn = find.byIcon(Icons.arrow_back);
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pump();

    expect(onBackCalled, isTrue);
  });

  testWidgets('StorePage calls onBack callback when provided', (tester) async {
    bool onBackCalled = false;

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<StoreBloc>(create: (_) => StoreBloc(FakeStoreRepository())),
          BlocProvider<CartCubit>(create: (_) => CartCubit()),
        ],
        child: MaterialApp(
          home: StorePage(
            onBack: () {
              onBackCalled = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final backBtn = find.byIcon(Icons.arrow_back);
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(onBackCalled, isTrue);
  });
}
