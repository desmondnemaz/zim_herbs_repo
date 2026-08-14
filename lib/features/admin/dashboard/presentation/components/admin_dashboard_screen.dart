import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/screens/admin_overview_screen.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/screens/admin_coming_soon_screen.dart';

/// Equivalent to the customer's [DashboardScreen] – renders the active admin
/// content section based on the sidebar nav index.
class AdminDashboardScreen extends StatelessWidget {
  final int activeIndex;
  final VoidCallback onToggleSidebar;

  const AdminDashboardScreen({
    super.key,
    required this.activeIndex,
    required this.onToggleSidebar,
  });

  static const _sectionTitles = [
    'Overview',
    'Herb Management',
    'Condition Management',
    'Treatment Management',
    'Marketplace',
    'User Management',
    'Reports',
    'Analytics',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body;
    switch (activeIndex) {
      case 0:
        body = const AdminOverviewScreen();
        break;
      default:
        body = AdminComingSoonScreen(
          title: _sectionTitles[activeIndex],
        );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: body,
      ),
    );
  }
}
