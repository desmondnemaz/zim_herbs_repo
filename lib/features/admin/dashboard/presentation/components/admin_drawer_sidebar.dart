import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zim_herbs_repo/core/components/portal_switch_dialog.dart';
import 'package:zim_herbs_repo/core/theme/spacing.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/home_page.dart';

class AdminDrawerSideBar extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onToggle;
  final int activeIndex;
  final ValueChanged<int> onNavTap;
  final UserModel? user;

  const AdminDrawerSideBar({
    super.key,
    this.isExpanded = true,
    this.onToggle,
    required this.activeIndex,
    required this.onNavTap,
    this.user,
  });

  @override
  State<AdminDrawerSideBar> createState() => _AdminDrawerSideBarState();
}

class _AdminDrawerSideBarState extends State<AdminDrawerSideBar> {
  List<_AdminNavItem> _getNavItems() {
    final isAdmin = widget.user?.canManageUsers ?? true;

    return [
      const _AdminNavItem(
        index: 0,
        label: 'Overview',
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        accentColor: Color(0xFF80CBC4), // Mint Teal
      ),
      const _AdminNavItem(
        index: 1,
        label: 'Moderation',
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        accentColor: Color(0xFFFFB74D), // Amber (matching Pending Reviews card)
      ),
      const _AdminNavItem(
        index: 2,
        label: 'Herb Mgmt',
        icon: Icons.local_florist_rounded,
        activeIcon: Icons.local_florist_rounded,
        accentColor: Color(0xFF81C784), // Herbal Green (matching Herbs card)
      ),
      const _AdminNavItem(
        index: 3,
        label: 'Conditions',
        icon: Icons.monitor_heart_outlined,
        activeIcon: Icons.monitor_heart_rounded,
        accentColor: Color(0xFF4DD0E1), // Medical Cyan/Teal (matching Conditions card)
      ),
      const _AdminNavItem(
        index: 4,
        label: 'Remedies',
        icon: Icons.healing_outlined,
        activeIcon: Icons.healing_rounded,
        accentColor: Color(0xFF64B5F6), // Healing Blue (matching Remedies card)
      ),
      const _AdminNavItem(
        index: 5,
        label: 'Marketplace',
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront_rounded,
        accentColor: Color(0xFFFFD54F), // Store Gold
      ),
      // Admin-only sections (strictly forbidden for moderators)
      if (isAdmin) ...[
        const _AdminNavItem(
          index: 6,
          label: 'Users',
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
          accentColor: Color(0xFFCE93D8), // Purple (matching Users card)
        ),
        const _AdminNavItem(
          index: 7,
          label: 'Reports',
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart_rounded,
          accentColor: Color(0xFFFF8A80), // Reports Coral
        ),
        const _AdminNavItem(
          index: 8,
          label: 'Analytics',
          icon: Icons.analytics_outlined,
          activeIcon: Icons.analytics_rounded,
          accentColor: Color(0xFF9FA8DA), // Analytics Indigo
        ),
      ],
    ];
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    final isAdmin = widget.user?.isAdmin ?? true;
    final headerTitle = isAdmin ? "ADMIN" : "MODERATION";
    final headerIcon = isAdmin ? Icons.admin_panel_settings : Icons.verified_user;

    if (isDesktop) {
      if (widget.isExpanded) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(headerIcon,
                        size: 28, color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        headerTitle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.menu_open, color: Colors.white),
                onPressed: widget.onToggle,
                tooltip: "Collapse Sidebar",
              ),
            ],
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: widget.onToggle,
                tooltip: "Expand Sidebar",
              ),
              const SizedBox(height: 12),
              Icon(headerIcon,
                  size: 28, color: Theme.of(context).colorScheme.secondary),
            ],
          ),
        );
      }
    } else {
      // Mobile Drawer Header
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                headerIcon,
                size: 48,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isAdmin ? "ADMIN PANEL" : "MODERATOR CONSOLE",
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFooter(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final showCollapsed = isDesktop && !widget.isExpanded;

    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 8),
          _buildNavItem(
            context,
            -2,
            const _AdminNavItem(
              index: -2,
              label: 'View Public App',
              icon: Icons.open_in_new_rounded,
              activeIcon: Icons.open_in_new_rounded,
              accentColor: Color(0xFF81C784),
            ),
            isPublicApp: true,
            forceCollapsed: showCollapsed,
          ),
          const SizedBox(height: 6),
          if (showCollapsed)
            _buildNavItem(
              context,
              -1,
              const _AdminNavItem(
                index: -1,
                label: 'Sign Out',
                icon: Icons.logout,
                activeIcon: Icons.logout,
              ),
              isSignOut: true,
              forceCollapsed: true,
            )
          else
            _buildNavItem(
              context,
              -1,
              const _AdminNavItem(
                index: -1,
                label: 'Sign Out',
                icon: Icons.logout,
                activeIcon: Icons.logout,
              ),
              isSignOut: true,
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    _AdminNavItem item, {
    bool isSignOut = false,
    bool isPublicApp = false,
    bool forceCollapsed = false,
  }) {
    final isDesktop = Responsive.isDesktop(context);
    final isExpanded = !isDesktop || widget.isExpanded;
    final isActive = !isSignOut && !isPublicApp && widget.activeIndex == item.index;

    final iconColor = (isSignOut || isPublicApp)
        ? Colors.white
        : isActive
            ? item.accentColor
            : item.accentColor.withValues(alpha: 0.88);

    final tileBackground = (isSignOut || isPublicApp)
        ? Colors.white.withValues(alpha: 0.12)
        : isActive
            ? item.accentColor.withValues(alpha: 0.22)
            : Colors.transparent;

    final textColor = isSignOut
        ? Colors.white
        : isActive
            ? item.accentColor
            : Colors.white.withValues(alpha: 0.88);

    void showSignOutConfirmation() {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFD32F2F)),
              SizedBox(width: 10),
              Text(
                'Sign Out',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to sign out of your account?',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                if (!Responsive.isDesktop(context)) Navigator.pop(context);
                context.read<AuthCubit>().signOut();
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    void showPublicAppConfirmation() async {
      final confirmed = await showPortalSwitchConfirmation(
        context: context,
        toAdmin: false,
      );
      if (confirmed && context.mounted) {
        if (!Responsive.isDesktop(context)) Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    }

    void handleTap() {
      if (isPublicApp) {
        showPublicAppConfirmation();
      } else if (isSignOut) {
        showSignOutConfirmation();
      } else {
        widget.onNavTap(item.index);
        if (!Responsive.isDesktop(context)) Navigator.pop(context);
      }
    }

    if (!isExpanded || forceCollapsed) {
      return Tooltip(
        message: item.label,
        preferBelow: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Material(
            color: tileBackground,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: handleTap,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: tileBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: handleTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: iconColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight:
                          (isActive || isSignOut || isPublicApp) ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final double targetWidth = widget.isExpanded ? 230 : 68;
    final navItems = _getNavItems();

    Widget content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, isDesktop),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(
                  navItems.length,
                  (i) => _buildNavItem(context, i, navItems[i]),
                ),
              ),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );

    if (isDesktop) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: targetWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.zero,
        ),
        child: ClipRect(
          child: OverflowBox(
            minWidth: targetWidth,
            maxWidth: targetWidth,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: targetWidth,
              child: content,
            ),
          ),
        ),
      );
    } else {
      return Drawer(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        child: content,
      );
    }
  }
}

class _AdminNavItem {
  final int index;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color accentColor;

  const _AdminNavItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.accentColor = Colors.white,
  });
}
