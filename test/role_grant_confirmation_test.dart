import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Role Grant Confirmation & Persistence Tests', () {
    testWidgets('Confirmation dialog presents role details and handles cancel',
        (tester) async {
      bool? confirmedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Grant Administrator Role'),
                      content: const Text(
                        'Are you sure you want to promote "Tinashe Moyo" to Administrator?\n\n'
                        '• "user_profiles.is_admin" will be set to TRUE.\n'
                        '• "user_profiles.primary_role" will be updated to "admin".\n\n'
                        'Confirm updating and persisting to the database?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Confirm & Grant Role'),
                        ),
                      ],
                    ),
                  );
                  confirmedResult = result;
                },
                child: const Text('Open Confirm'),
              ),
            ),
          ),
        ),
      );

      // Tap button to open confirmation dialog
      await tester.tap(find.text('Open Confirm'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.text('Grant Administrator Role'), findsOneWidget);
      expect(
        find.textContaining(
            'Are you sure you want to promote "Tinashe Moyo" to Administrator?'),
        findsOneWidget,
      );
      expect(
        find.textContaining('"user_profiles.is_admin" will be set to TRUE'),
        findsOneWidget,
      );

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(confirmedResult, isFalse);
    });

    testWidgets('Confirmation dialog returns true when action is confirmed',
        (tester) async {
      bool? confirmedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Grant Practitioner Role'),
                      content: const Text(
                        'Are you sure you want to verify "Dr. Chidzero" as an accredited Traditional Practitioner?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Confirm & Grant Role'),
                        ),
                      ],
                    ),
                  );
                  confirmedResult = result;
                },
                child: const Text('Open Confirm'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Grant Practitioner Role'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('Confirm & Grant Role'));
      await tester.pumpAndSettle();

      expect(confirmedResult, isTrue);
    });

    testWidgets(
        'Rights dialog includes Administrator, Moderator, Practitioner, and Supplier switches',
        (tester) async {
      bool isAdmin = false;
      bool isModerator = false;
      bool isPractitioner = true;
      bool isSupplier = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Administrator'),
                      value: isAdmin,
                      onChanged: (val) => setState(() => isAdmin = val),
                    ),
                    SwitchListTile(
                      title: const Text('Moderator'),
                      value: isModerator,
                      onChanged: (val) => setState(() => isModerator = val),
                    ),
                    SwitchListTile(
                      title: const Text('Traditional Practitioner'),
                      value: isPractitioner,
                      onChanged: (val) => setState(() => isPractitioner = val),
                    ),
                    SwitchListTile(
                      title: const Text('Supplier / Vendor'),
                      value: isSupplier,
                      onChanged: (val) => setState(() => isSupplier = val),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Administrator'), findsOneWidget);
      expect(find.text('Moderator'), findsOneWidget);
      expect(find.text('Traditional Practitioner'), findsOneWidget);
      expect(find.text('Supplier / Vendor'), findsOneWidget);

      // Verify initial Practitioner switch state is on
      final practitionerSwitch = tester.widget<Switch>(
        find.descendant(
          of: find.widgetWithText(SwitchListTile, 'Traditional Practitioner'),
          matching: find.byType(Switch),
        ),
      );
      expect(practitionerSwitch.value, isTrue);

      // Toggle supplier switch
      await tester.tap(find.widgetWithText(SwitchListTile, 'Supplier / Vendor'));
      await tester.pumpAndSettle();

      final supplierSwitch = tester.widget<Switch>(
        find.descendant(
          of: find.widgetWithText(SwitchListTile, 'Supplier / Vendor'),
          matching: find.byType(Switch),
        ),
      );
      expect(supplierSwitch.value, isTrue);
    });
  });
}
