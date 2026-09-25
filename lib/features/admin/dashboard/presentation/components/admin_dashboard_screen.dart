import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/screens/admin_overview_screen.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/screens/admin_coming_soon_screen.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/pages/herbs_list.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/condition_list.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/pages/remedies_list.dart';
import 'package:zim_herbs_repo/features/marketplace/store/presentation/store_page.dart';
import 'package:zim_herbs_repo/features/admin/user_management/presentation/user_management_screen.dart';

/// Renders the active admin content section based on the sidebar nav index.
class AdminDashboardScreen extends StatelessWidget {
  final int activeIndex;
  final VoidCallback onToggleSidebar;
  final ValueChanged<int>? onNavigate;

  const AdminDashboardScreen({
    super.key,
    required this.activeIndex,
    required this.onToggleSidebar,
    this.onNavigate,
  });

  static const _sectionTitles = [
    'Overview',
    'Herb Management',
    'Condition Management',
    'Remedy Management',
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
        body = AdminOverviewScreen(onNavigate: onNavigate);
        break;
      case 1:
        body = const HerbsList();
        break;
      case 2:
        body = const ConditionsListPage();
        break;
      case 3:
        body = const RemediesList();
        break;
      case 4:
        body = const StorePage();
        break;
      case 5:
        body = const UserManagementScreen();
        break;
      case 6:
        body = const AdminComingSoonScreen(title: 'Reports');
        break;
      case 7:
        body = const AdminComingSoonScreen(title: 'Analytics');
        break;
      default:
        body = AdminComingSoonScreen(
          title: activeIndex < _sectionTitles.length
              ? _sectionTitles[activeIndex]
              : 'Admin Section',
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
