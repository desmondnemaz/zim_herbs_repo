import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zim_herbs_repo/core/components/batch_action_toolbar.dart';

void main() {
  group('BatchActionToolbar', () {
    testWidgets('renders normal mode with count and Mark / Select toggle', (tester) async {
      bool enterCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchActionToolbar(
              isSelectionMode: false,
              totalCount: 15,
              itemLabel: 'herbs',
              selectedCount: 0,
              onEnterSelectionMode: () => enterCalled = true,
              onCancelSelection: () {},
            ),
          ),
        ),
      );

      expect(find.text('Total: 15 herbs'), findsOneWidget);
      expect(find.text('Mark / Select'), findsOneWidget);
      expect(find.byIcon(Icons.checklist_rtl_rounded), findsOneWidget);

      await tester.tap(find.text('Mark / Select'));
      expect(enterCalled, isTrue);
    });

    testWidgets('renders selection mode with marked count and controls', (tester) async {
      bool cancelCalled = false;
      bool toggleSelectAllCalled = false;
      bool deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchActionToolbar(
              isSelectionMode: true,
              totalCount: 15,
              itemLabel: 'herbs',
              selectedCount: 3,
              isAllSelected: false,
              onEnterSelectionMode: () {},
              onCancelSelection: () => cancelCalled = true,
              onToggleSelectAll: () => toggleSelectAllCalled = true,
              onDeleteSelected: () => deleteCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('3 marked'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('Delete (3)'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      expect(cancelCalled, isTrue);

      await tester.tap(find.text('Select All'));
      expect(toggleSelectAllCalled, isTrue);

      await tester.tap(find.text('Delete (3)'));
      expect(deleteCalled, isTrue);
    });

    testWidgets('renders Deselect All when isAllSelected is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchActionToolbar(
              isSelectionMode: true,
              totalCount: 5,
              itemLabel: 'herbs',
              selectedCount: 5,
              isAllSelected: true,
              onEnterSelectionMode: () {},
              onCancelSelection: () {},
              onToggleSelectAll: () {},
              onDeleteSelected: () {},
            ),
          ),
        ),
      );

      expect(find.text('5 marked'), findsOneWidget);
      expect(find.text('Deselect All'), findsOneWidget);
    });
  });
}
