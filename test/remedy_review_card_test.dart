import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zim_herbs_repo/core/components/remedy_review_card.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/repository/remedies/domain/entities/remedy.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/components/desktop_remedy_list.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/components/mobile_remedy_list.dart';

void main() {
  const testRemedy = Remedy(
    id: 'r1',
    conditionId: 'c1',
    name: 'Herbal Cough Infusion',
    methodOfUse: 'Drink twice daily',
    preparation: 'Boil zumbani leaves and ginger in hot water for 10 minutes.',
    dosageAdults: '1 cup in morning and evening',
    conditionName: 'Respiratory Infection',
    conditionBodySystem: BodySystem.respiratory,
    isApproved: true,
    validationStatus: RecordValidationStatus.published,
    remedyHerbs: [
      RemedyHerb(
        id: 'rh1',
        remedyId: 'r1',
        herbId: 'h1',
        herbName: 'Zumbani',
      ),
      RemedyHerb(
        id: 'rh2',
        remedyId: 'r1',
        herbId: 'h2',
        herbName: 'Ginger',
      ),
    ],
  );

  group('RemedyReviewCard Tests', () {
    testWidgets('Renders name, condition subtitle, herbs count, and View Details',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemedyReviewCard(
              remedy: testRemedy,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Verify remedy name
      expect(find.text('Zumbani + Ginger'), findsOneWidget);

      // Verify target condition
      expect(find.text('Target Condition: Respiratory Infection'), findsOneWidget);

      // Verify herbs count & body system
      expect(find.text('2 herbs included • Respiratory'), findsOneWidget);

      // Verify View Details button
      expect(find.text('View Details'), findsOneWidget);

      // Tap View Details
      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('Renders moderation menu and triggers approval, edit, and delete',
        (tester) async {
      bool toggleApprovalCalled = false;
      bool editCalled = false;
      bool deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemedyReviewCard(
              remedy: testRemedy,
              onTap: () {},
              onToggleApproval: () {
                toggleApprovalCalled = true;
              },
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

      expect(find.text('Unapprove'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Unapprove'));
      await tester.pumpAndSettle();
      expect(toggleApprovalCalled, isTrue);
      expect(editCalled, isFalse);
      expect(deleteCalled, isFalse);
    });

    testWidgets('Does not render moderation menu when callbacks are null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemedyReviewCard(
              remedy: testRemedy,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });
  });

  group('Remedy Lists Integration Tests', () {
    testWidgets('MobileRemedyList renders RemedyReviewCard items',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final rs = ResponsiveSize(context);
                return MobileRemedyList(
                  remedies: const [testRemedy],
                  rs: rs,
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(RemedyReviewCard), findsOneWidget);
      expect(find.text('Zumbani + Ginger'), findsOneWidget);
    });

    testWidgets('DesktopRemedyList renders RemedyReviewCard items',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final rs = ResponsiveSize(context);
                return DesktopRemedyList(
                  remedies: const [testRemedy],
                  rs: rs,
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(RemedyReviewCard), findsOneWidget);
      expect(find.text('Zumbani + Ginger'), findsOneWidget);
    });
  });
}
