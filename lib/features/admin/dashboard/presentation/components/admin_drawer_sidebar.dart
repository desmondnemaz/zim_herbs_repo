import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zim_herbs_repo/core/theme/spacing.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';

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
      ),
      const _AdminNavItem(
        index: 1,
        label: 'Moderation',
        icon: Icons.verified_user_outlined,
        activeIcon: Icons.verified_user,
      ),
      const _AdminNavItem(
        index: 2,
        label: 'Herb Mgmt',
        icon: Icons.local_florist_outlined,
        activeIcon: Icons.local_florist,
      ),
      const _AdminNavItem(
        index: 3,
        label: 'Conditions',
        icon: Icons.sick_outlined,
        activeIcon: Icons.sick,
      ),
      const _AdminNavItem(
        index: 4,
        label: 'Remedies',
        icon: Icons.healing_outlined,
        activeIcon: Icons.healing,
      ),
      const _AdminNavItem(
        index: 5,
        label: 'Marketplace',
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
      ),
      // Admin-only sections (strictly forbidden for moderators)
      if (isAdmin) ...[
        const _AdminNavItem(
          index: 6,
          label: 'Users',
          icon: Icons.people_outline,
          activeIcon: Icons.people,
        ),
        const _AdminNavItem(
          index: 7,
          label: 'Reports',
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart,
        ),
        const _AdminNavItem(
          index: 8,
          label: 'Analytics',
          icon: Icons.analytics_outlined,
          activeIcon: Icons.analytics,
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
    bool forceCollapsed = false,
  }) {
    final isDesktop = Responsive.isDesktop(context);
    final isExpanded = !isDesktop || widget.isExpanded;
    final isActive = !isSignOut && widget.activeIndex == item.index;

    final iconColor = isSignOut
        ? Colors.redAccent
        : isActive
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7);

    void handleTap() {
      if (isSignOut) {
        if (!Responsive.isDesktop(context)) Navigator.pop(context);
        context.read<AuthCubit>().signOut();
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
            color: isActive
                ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)
                : Colors.transparent,
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
        color: isActive
            ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)
            : Colors.transparent,
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
                      color: isSignOut
                          ? Colors.redAccent
                          : isActive
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withValues(alpha: 0.85),
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
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

  const _AdminNavItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
