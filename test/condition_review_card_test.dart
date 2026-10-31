import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zim_herbs_repo/core/components/condition_review_card.dart';
import 'package:zim_herbs_repo/core/components/public_condition_card.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/entities/body_part.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/entities/condition.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/components/desktop_condition_list.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/components/mobile_condition_list.dart';

void main() {
  const testCondition = Condition(
    id: 'c1',
    name: 'Asthma',
    bodySystem: BodySystem.respiratory,
    description: 'Chronic inflammation of the airways causing wheezing.',
    symptoms: ['Wheezing', 'Shortness of breath', 'Coughing'],
    precautions: ['Avoid cold air', 'Keep inhaler close'],
    bodyParts: [
      BodyPart(id: 'bp1', nameEn: 'Lungs'),
      BodyPart(id: 'bp2', nameEn: 'Throat'),
    ],
  );

  group('ConditionReviewCard Tests', () {
    testWidgets('Renders name, system chip, body parts, symptoms and view button',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConditionReviewCard(
              condition: testCondition,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Verify name
      expect(find.text('Asthma'), findsOneWidget);

      // Verify BodySystem label chip
      expect(find.text('Respiratory'), findsOneWidget);

      // Verify targeted body parts
      expect(find.text('Targeted: Lungs, Throat'), findsOneWidget);

      // Verify symptoms and precautions summary
      expect(find.text('3 symptoms • 2 precautions'), findsOneWidget);

      // Verify View Details button
      expect(find.text('View Details'), findsOneWidget);

      // Tap View Details
      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('Shows popup menu with edit and delete when callbacks provided',
        (tester) async {
      bool editCalled = false;
      bool deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConditionReviewCard(
              condition: testCondition,
              onTap: () {},
              onEdit: () {
                editCalled = true;
              },
              onDelete: () {
                deleteCalled = true;
              },
            ),
          ),
        ),
      );

      final menuBtn = find.byIcon(Icons.more_vert);
      expect(menuBtn, findsOneWidget);

      await tester.tap(menuBtn);
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(editCalled, isTrue);
      expect(deleteCalled, isFalse);
    });

    testWidgets('Does not show popup menu when onEdit and onDelete are null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConditionReviewCard(
              condition: testCondition,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });
  });

  group('Condition Lists Integration Tests', () {
    testWidgets('MobileConditionList renders ConditionReviewCard items',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final rs = ResponsiveSize(context);
                return MobileConditionList(
                  conditions: const [testCondition],
                  rs: rs,
                  onRefresh: () async {},
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(ConditionReviewCard), findsOneWidget);
      expect(find.text('Asthma'), findsOneWidget);
    });

    testWidgets('DesktopConditionList renders ConditionReviewCard items',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final rs = ResponsiveSize(context);
                return DesktopConditionList(
                  conditions: const [testCondition],
                  rs: rs,
                  onRefresh: () async {},
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(ConditionReviewCard), findsOneWidget);
      expect(find.text('Asthma'), findsOneWidget);
    });

    testWidgets('Public view renders PublicConditionCard with Explore Remedies and no edit/delete',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final rs = ResponsiveSize(context);
                return MobileConditionList(
                  conditions: const [testCondition],
                  rs: rs,
                  isPublicView: true,
                  onRefresh: () async {},
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(PublicConditionCard), findsOneWidget);
      expect(find.byType(ConditionReviewCard), findsNothing);
      expect(find.text('Explore Remedies'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    });
  });
}

