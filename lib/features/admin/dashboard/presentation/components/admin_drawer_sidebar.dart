import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zim_herbs_repo/core/theme/spacing.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';

class AdminDrawerSideBar extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onToggle;
  final int activeIndex;
  final ValueChanged<int> onNavTap;

  const AdminDrawerSideBar({
    super.key,
    this.isExpanded = true,
    this.onToggle,
    required this.activeIndex,
    required this.onNavTap,
  });

  @override
  State<AdminDrawerSideBar> createState() => _AdminDrawerSideBarState();
}

class _AdminDrawerSideBarState extends State<AdminDrawerSideBar> {
  static const _navItems = [
    _AdminNavItem(label: 'Overview', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard),
    _AdminNavItem(label: 'Herb Mgmt', icon: Icons.local_florist_outlined, activeIcon: Icons.local_florist),
    _AdminNavItem(label: 'Conditions', icon: Icons.sick_outlined, activeIcon: Icons.sick),
    _AdminNavItem(label: 'Treatments', icon: Icons.healing_outlined, activeIcon: Icons.healing),
    _AdminNavItem(label: 'Marketplace', icon: Icons.storefront_outlined, activeIcon: Icons.storefront),
    _AdminNavItem(label: 'Users', icon: Icons.people_outline, activeIcon: Icons.people),
    _AdminNavItem(label: 'Reports', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart),
    _AdminNavItem(label: 'Analytics', icon: Icons.analytics_outlined, activeIcon: Icons.analytics),
  ];

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    if (isDesktop) {
      if (widget.isExpanded) {
        return ClipRect(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings,
                          size: 28, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "ADMIN",
                          overflow: TextOverflow.clip,
                          softWrap: false,
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
              Icon(Icons.admin_panel_settings,
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
                Icons.admin_panel_settings,
                size: 48,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "ADMIN PANEL",
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

    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 8),
            if (showCollapsed)
              _buildNavItem(context, 6, const _AdminNavItem(label: 'Sign Out', icon: Icons.logout, activeIcon: Icons.logout), isSignOut: true, forceCollapsed: true)
            else
              _buildNavItem(context, 6, const _AdminNavItem(label: 'Sign Out', icon: Icons.logout, activeIcon: Icons.logout), isSignOut: true),
          ],
        ),
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
    final isActive = !isSignOut && widget.activeIndex == index;

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
        widget.onNavTap(index);
        if (!Responsive.isDesktop(context)) Navigator.pop(context);
      }
    }

    if (!isExpanded || forceCollapsed) {
      return Tooltip(
        message: item.label,
        preferBelow: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: InkWell(
            onTap: handleTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          dense: true,
          onTap: handleTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(
            isActive ? item.activeIcon : item.icon,
            color: iconColor,
            size: 22,
          ),
          title: Text(
            item.label,
            style: TextStyle(
              color: isSignOut
                  ? Colors.redAccent
                  : isActive
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.85),
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    Widget content = SafeArea(
      child: Column(
        children: [
          _buildHeader(context, isDesktop),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(
                  _navItems.length,
                  (i) => _buildNavItem(context, i, _navItems[i]),
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
        width: widget.isExpanded ? 230 : 68,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.zero,
        ),
        child: content,
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
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _AdminNavItem({required this.label, required this.icon, required this.activeIcon});
}
