import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/components/admin_drawer_sidebar.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/drawer_sidebar.dart';

void main() {
  testWidgets('AdminDrawerSideBar toggling test', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    bool isExpanded = true;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Row(
                children: [
                  AdminDrawerSideBar(
                    isExpanded: isExpanded,
                    onToggle: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                    activeIndex: 0,
                    onNavTap: (_) {},
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            );
          },
        ),
      ),
    );

    // Initial render
    await tester.pumpAndSettle();

    // Tap collapse
    final collapseBtn = find.byTooltip('Collapse Sidebar');
    expect(collapseBtn, findsOneWidget);
    await tester.tap(collapseBtn);

    // Pump intermediate frames during the 250ms animation
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    // Tap expand
    final expandBtn = find.byTooltip('Expand Sidebar');
    expect(expandBtn, findsOneWidget);
    await tester.tap(expandBtn);

    // Pump intermediate frames during the 250ms animation
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
  });

  testWidgets('DrawerSideBar toggling test', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    bool isExpanded = true;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Row(
                children: [
                  DrawerSideBar(
                    isExpanded: isExpanded,
                    onToggle: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    final collapseBtn = find.byTooltip('Collapse Sidebar');
    expect(collapseBtn, findsOneWidget);
    await tester.tap(collapseBtn);

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    final expandBtn = find.byTooltip('Expand Sidebar');
    expect(expandBtn, findsOneWidget);
    await tester.tap(expandBtn);

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
  });
}
