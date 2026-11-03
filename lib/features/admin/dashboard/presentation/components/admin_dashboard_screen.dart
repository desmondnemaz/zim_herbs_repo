import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/screens/admin_overview_screen.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/screens/admin_reports_screen.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/screens/admin_analytics_screen.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/screens/admin_coming_soon_screen.dart';
import 'package:zim_herbs_repo/features/admin/moderation/presentation/screens/moderation_hub_screen.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/pages/herbs_list.dart';
import 'package:zim_herbs_repo/features/repository/ailments/presentation/ailment_list.dart';
import 'package:zim_herbs_repo/features/admin/ailment_management/presentation/body_parts_page.dart';
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
    'Ailment Management',
    'Remedy Management',
    'Marketplace',
    'User Management',
    'Reports',
    'Analytics',
    'Body Parts',
  ];

  @override
  Widget build(BuildContext context) {
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
        body = ModerationHubScreen(
          moderator: effectiveUser,
          onBack: () => onNavigate?.call(0),
        );
        break;
      case 2:
        body = HerbsList(onBack: () => onNavigate?.call(0));
        break;
      case 3:
        body = AilmentsListPage(onBack: () => onNavigate?.call(0));
        break;
      case 9:
        body = BodyPartsPage(onBack: () => onNavigate?.call(0));
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
          body = UserManagementScreen(onBack: () => onNavigate?.call(0));
        } else {
          body = ModerationHubScreen(
            moderator: effectiveUser,
            onBack: () => onNavigate?.call(0),
          );
        }
        break;
      case 7:
        if (effectiveUser.isAdmin) {
          body = AdminReportsScreen(
            onBack: () => onNavigate?.call(0),
          );
        } else {
          body = ModerationHubScreen(
            moderator: effectiveUser,
            onBack: () => onNavigate?.call(0),
          );
        }
        break;
      case 8:
        if (effectiveUser.isAdmin) {
          body = AdminAnalyticsScreen(
            onBack: () => onNavigate?.call(0),
          );
        } else {
          body = ModerationHubScreen(
            moderator: effectiveUser,
            onBack: () => onNavigate?.call(0),
          );
        }
        break;
      default:
        body = AdminComingSoonScreen(
          title: activeIndex < _sectionTitles.length
              ? _sectionTitles[activeIndex]
              : 'Admin Section',
          onBack: () => onNavigate?.call(0),
        );
    }

    return body;
  }
}
