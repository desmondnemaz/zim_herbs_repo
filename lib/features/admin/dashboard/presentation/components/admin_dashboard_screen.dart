import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/screens/admin_overview_screen.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/screens/admin_coming_soon_screen.dart';
import 'package:zim_herbs_repo/features/admin/moderation/presentation/screens/moderation_hub_screen.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/pages/herbs_list.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/condition_list.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/pages/remedies_list.dart';
import 'package:zim_herbs_repo/features/marketplace/store/presentation/store_page.dart';
import 'package:zim_herbs_repo/features/admin/user_management/presentation/user_management_screen.dart';

/// Renders the active admin or moderation content section based on the sidebar nav index.
class AdminDashboardScreen extends StatelessWidget {
  final int activeIndex;
  final VoidCallback onToggleSidebar;
  final ValueChanged<int>? onNavigate;
  final UserModel? user;

  const AdminDashboardScreen({
    super.key,
    required this.activeIndex,
    required this.onToggleSidebar,
    this.onNavigate,
    this.user,
  });

  static const _sectionTitles = [
    'Overview',
    'Moderation Hub',
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
    final effectiveUser = user ??
        const UserModel(
          id: '',
          name: 'Staff',
          email: '',
          role: UserRole.moderator,
        );

    Widget body;
    switch (activeIndex) {
      case 0:
        body = AdminOverviewScreen(onNavigate: onNavigate, user: effectiveUser);
        break;
      case 1:
        body = ModerationHubScreen(moderator: effectiveUser);
        break;
      case 2:
        body = HerbsList(onBack: () => onNavigate?.call(0));
        break;
      case 3:
        body = ConditionsListPage(onBack: () => onNavigate?.call(0));
        break;
      case 4:
        body = RemediesList(onBack: () => onNavigate?.call(0));
        break;
      case 5:
        body = StorePage(onBack: () => onNavigate?.call(0));
        break;
      case 6:
        // Admin privilege guard: only Admins can manage users!
        if (effectiveUser.canManageUsers) {
          body = const UserManagementScreen();
        } else {
          body = ModerationHubScreen(moderator: effectiveUser);
        }
        break;
      case 7:
        if (effectiveUser.isAdmin) {
          body = const AdminComingSoonScreen(title: 'Reports');
        } else {
          body = ModerationHubScreen(moderator: effectiveUser);
        }
        break;
      case 8:
        if (effectiveUser.isAdmin) {
          body = const AdminComingSoonScreen(title: 'Analytics');
        } else {
          body = ModerationHubScreen(moderator: effectiveUser);
        }
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
