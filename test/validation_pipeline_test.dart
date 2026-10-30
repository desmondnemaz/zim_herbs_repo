import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zim_herbs_repo/core/components/rejection_reason_dialog.dart';
import 'package:zim_herbs_repo/core/components/validation_status_chip.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';
import 'package:zim_herbs_repo/features/repository/remedies/domain/entities/remedy.dart';

void main() {
  group('RecordValidationStatus Enum & Parsing Tests', () {
    test('fromString parses known database strings correctly', () {
      expect(
        RecordValidationStatus.fromString('submitted'),
        equals(RecordValidationStatus.submitted),
      );
      expect(
        RecordValidationStatus.fromString('under_review'),
        equals(RecordValidationStatus.underReview),
      );
      expect(
        RecordValidationStatus.fromString('validated'),
        equals(RecordValidationStatus.validated),
      );
      expect(
        RecordValidationStatus.fromString('published'),
        equals(RecordValidationStatus.published),
      );
      expect(
        RecordValidationStatus.fromString('rejected'),
        equals(RecordValidationStatus.rejected),
      );
    });

    test('fromString safely backfills from legacy isApproved when null', () {
      expect(
        RecordValidationStatus.fromString(null, isApproved: true),
        equals(RecordValidationStatus.published),
      );
      expect(
        RecordValidationStatus.fromString(null, isApproved: false),
        equals(RecordValidationStatus.submitted),
      );
    });
  });

  group('Record Audit History Timeline Generation', () {
    test('Herb auditHistory generates 4 stages for published record', () {
      final herb = Herb(
        id: 'herb-1',
        nameEn: 'Moringa',
        isApproved: true,
        validationStatus: RecordValidationStatus.published,
        submittedBy: 'user-1',
        submittedAt: DateTime(2026, 1, 1),
        reviewedBy: 'mod-1',
        reviewedAt: DateTime(2026, 1, 2),
        verifiedBy: 'expert-1',
        verifiedAt: DateTime(2026, 1, 3),
        publishedBy: 'admin-1',
        publishedAt: DateTime(2026, 1, 4),
      );

      final history = herb.auditHistory;
      expect(history.length, equals(4));
      expect(history[0].stage, equals(RecordValidationStatus.submitted));
      expect(history[0].isCompleted, isTrue);
      expect(history[1].stage, equals(RecordValidationStatus.underReview));
      expect(history[1].isCompleted, isTrue);
      expect(history[2].stage, equals(RecordValidationStatus.validated));
      expect(history[2].isCompleted, isTrue);
      expect(history[3].stage, equals(RecordValidationStatus.published));
      expect(history[3].isCompleted, isTrue);
      expect(history[3].actorId, equals('admin-1'));
    });

    test('Remedy auditHistory generates rejection stage with comment', () {
      final remedy = Remedy(
        id: 'rem-1',
        name: 'Herbal Tonic',
        conditionId: 'cond-1',
        methodOfUse: 'Oral decoction',
        preparation: 'Boil roots in water',
        isApproved: false,
        validationStatus: RecordValidationStatus.rejected,
        submittedBy: 'user-2',
        submittedAt: DateTime(2026, 1, 10),
        rejectedBy: 'mod-2',
        rejectedAt: DateTime(2026, 1, 12),
        rejectionReason: 'Missing dosage guidelines for children.',
      );

      final history = remedy.auditHistory;
      expect(history.length, equals(4));
      final rejectionStep = history.last;
      expect(rejectionStep.stage, equals(RecordValidationStatus.rejected));
      expect(rejectionStep.notes, equals('Missing dosage guidelines for children.'));
      expect(rejectionStep.actorId, equals('mod-2'));
      expect(rejectionStep.isCurrent, isTrue);
    });
  });

  group('ValidationStatusChip Widget Tests', () {
    testWidgets('renders stage label and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ValidationStatusChip(
              status: RecordValidationStatus.underReview,
            ),
          ),
        ),
      );

      expect(find.text('Under Review'), findsOneWidget);
      expect(find.byIcon(Icons.rate_review_outlined), findsOneWidget);
    });
  });

  group('RejectionReasonDialog Widget Tests', () {
    testWidgets('submit button is disabled when input is too short or empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RejectionReasonDialog(
              recordName: 'Test Herb',
              recordType: 'Herb',
            ),
          ),
        ),
      );

      final confirmButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm Rejection'),
      );
      expect(confirmButton.onPressed, isNull);

      // Enter valid explanation
      await tester.enterText(find.byType(TextFormField), 'Inaccurate scientific documentation.');
      await tester.pump();

      final updatedButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm Rejection'),
      );
      expect(updatedButton.onPressed, isNotNull);
    });
  });
}
