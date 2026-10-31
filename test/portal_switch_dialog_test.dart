import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zim_herbs_repo/core/components/portal_switch_dialog.dart';

void main() {
  group('PortalSwitchConfirmationDialog Tests', () {
    testWidgets('shows correct content for switching to Admin and cancels',
        (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showPortalSwitchConfirmation(
                    context: context,
                    toAdmin: true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Switch to Admin Console?'), findsOneWidget);
      expect(
        find.text(
          'You are about to switch to the administrative and moderation console. Do you want to proceed?',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Switch to Admin'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('confirms switching to Admin', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showPortalSwitchConfirmation(
                    context: context,
                    toAdmin: true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Switch to Admin'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('shows correct content for switching to Public and confirms',
        (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showPortalSwitchConfirmation(
                    context: context,
                    toAdmin: false,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Switch to Public App?'), findsOneWidget);
      expect(
        find.text(
          'You are about to switch to the public catalog and herbal marketplace. Do you want to proceed?',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Switch to Public'), findsOneWidget);

      await tester.tap(find.text('Switch to Public'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
