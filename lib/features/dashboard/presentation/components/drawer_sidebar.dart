import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/components/portal_switch_dialog.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/admin_dashboard_page.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';
import 'package:zim_herbs_repo/features/settings/presentation/settings_page.dart';
import 'package:zim_herbs_repo/features/notifications/presentation/notifications_page.dart';


class _PublicNavItem {
  final int index;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color accentColor;
  final String? badgeText;

  const _PublicNavItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.accentColor,
    this.badgeText,
  });
}

class DrawerSideBar extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onToggle;
  final int activeIndex;
  final ValueChanged<int>? onNavTap;

  const DrawerSideBar({
    super.key,
    this.isExpanded = true,
    this.onToggle,
    this.activeIndex = 0,
    this.onNavTap,
  });

  @override
  State<DrawerSideBar> createState() => _DrawerSideBarState();
}

class _DrawerSideBarState extends State<DrawerSideBar> {
  static const List<_PublicNavItem> _navItems = [
    _PublicNavItem(
      index: 0,
      label: 'Dashboard',
      icon: Icons.grid_view_rounded,
      activeIcon: Icons.grid_view_rounded,
      accentColor: Color(0xFF80CBC4),
    ),
    _PublicNavItem(
      index: 1,
      label: 'Herbs',
      icon: Icons.local_florist_rounded,
      activeIcon: Icons.local_florist_rounded,
      accentColor: Color(0xFF81C784),
    ),
    _PublicNavItem(
      index: 2,
      label: 'Ailments',
      icon: Icons.monitor_heart_rounded,
      activeIcon: Icons.monitor_heart_rounded,
      accentColor: Color(0xFF4DD0E1),
    ),
    _PublicNavItem(
      index: 3,
      label: 'Remedies',
      icon: Icons.healing_rounded,
      activeIcon: Icons.healing_rounded,
      accentColor: Color(0xFF64B5F6),
    ),
    _PublicNavItem(
      index: 4,
      label: 'Marketplace',
      icon: Icons.storefront_rounded,
      activeIcon: Icons.storefront_rounded,
      accentColor: Color(0xFFFFD54F),
      badgeText: 'Soon',
    ),
    _PublicNavItem(
      index: 5,
      label: 'Contributions',
      icon: Icons.volunteer_activism_rounded,
      activeIcon: Icons.volunteer_activism_rounded,
      accentColor: Color(0xFFFF8A80),
    ),
    _PublicNavItem(
      index: 6,
      label: 'Telemedicine',
      icon: Icons.medical_services_rounded,
      activeIcon: Icons.medical_services_rounded,
      accentColor: Color(0xFFCE93D8),
      badgeText: 'Soon',
    ),
  ];

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    if (isDesktop) {
      if (widget.isExpanded) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Image.asset(
                      'assets/logo/logo.png',
                      height: 32,
                      width: 32,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (_, _, _) => Icon(
                            Icons.grass,
                            size: 32,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "ZIM-HERBS",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
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
              Image.asset(
                'assets/logo/logo.png',
                height: 32,
                width: 32,
                fit: BoxFit.contain,
                errorBuilder:
                    (_, _, _) => Icon(
                      Icons.grass,
                      size: 32,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
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
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.grass,
                size: 64,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "ZIM HERBS",
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    bool canModerate = false;
    UserModel? currentUser;
    try {
      final authState = context.watch<AuthCubit>().state;
      if (authState is Authenticated && authState.user.canModerate) {
        canModerate = true;
        currentUser = authState.user;
      }
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
            height: 1,
          ),
          const SizedBox(height: 8),

          // ── Admin Console Action (for moderators & admins) ──
          if (canModerate && currentUser != null) ...[
            _buildMenuItem(
              title: "Admin Console",
              icon: Icons.admin_panel_settings_rounded,
              iconColor: const Color(0xFF81C784),
              isActive: false,
              isActionTile: true,
              onTap: () => _showAdminConsoleConfirmation(context, currentUser!),
            ),
            const SizedBox(height: 6),
          ],

          // ── Sign Out Action ──
          _buildMenuItem(
            title: "Sign Out",
            icon: Icons.logout_rounded,
            isActive: false,
            isSignOut: true,
            onTap: () => _showSignOutConfirmation(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final double targetWidth = widget.isExpanded ? 250 : 70;

    Widget content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Sidebar Header ──
          _buildHeader(context, isDesktop),

          // ── Scrollable Menu ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ..._navItems.map((item) {
                    final isActive = widget.activeIndex == item.index;
                    return _buildMenuItem(
                      title: item.label,
                      icon: isActive ? item.activeIcon : item.icon,
                      iconColor: item.accentColor,
                      badgeText: item.badgeText,
                      isActive: isActive,
                      onTap: () {
                        if (!Responsive.isDesktop(context)) {
                          Navigator.pop(context);
                        }
                        widget.onNavTap?.call(item.index);
                      },
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Divider(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.15),
                      height: 1,
                    ),
                  ),
                  _buildMenuItem(
                    title: "Notifications",
                    icon: Icons.notifications_rounded,
                    iconColor: const Color(0xFFFFB74D),
                    isActive: false,
                    onTap: () {
                      if (!Responsive.isDesktop(context)) {
                        Navigator.pop(context);
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    title: "Settings",
                    icon: Icons.settings_rounded,
                    iconColor: const Color(0xFF64B5F6),
                    isActive: false,
                    onTap: () {
                      if (!Responsive.isDesktop(context)) {
                        Navigator.pop(context);
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Sidebar Footer ──
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

  Widget _buildMenuItem({
    required String title,
    String? svgSrc,
    IconData? icon,
    required bool isActive,
    bool isSignOut = false,
    bool isActionTile = false,
    Color? iconColor,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    final isDesktop = Responsive.isDesktop(context);
    final isExpanded = !isDesktop || widget.isExpanded;
    final accentColor = iconColor ?? Theme.of(context).colorScheme.secondary;

    final itemColor = (isSignOut || isActionTile)
        ? (iconColor ?? Colors.white)
        : isActive
            ? accentColor
            : accentColor.withValues(alpha: 0.88);

    final tileBackground = (isSignOut || isActionTile)
        ? Colors.white.withValues(alpha: 0.12)
        : isActive
            ? accentColor.withValues(alpha: 0.22)
            : Colors.transparent;

    final textColor = (isSignOut || isActionTile)
        ? Colors.white
        : isActive
            ? accentColor
            : Colors.white.withValues(alpha: 0.88);

    if (!isExpanded) {
      final childWidget =
          svgSrc != null
              ? SvgPicture.asset(
                svgSrc,
                colorFilter: ColorFilter.mode(
                  itemColor,
                  BlendMode.srcIn,
                ),
                height: 24,
                width: 24,
              )
              : Icon(
                icon,
                color: itemColor,
                size: 24,
              );

      return Tooltip(
        message: badgeText != null ? "$title ($badgeText)" : title,
        preferBelow: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Material(
            color: tileBackground,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(child: childWidget),
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                svgSrc != null
                    ? SvgPicture.asset(
                      svgSrc,
                      colorFilter: ColorFilter.mode(
                        itemColor,
                        BlendMode.srcIn,
                      ),
                      height: 24,
                      width: 24,
                    )
                    : Icon(
                      icon,
                      color: itemColor,
                      size: 24,
                    ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight:
                          (isActive || isSignOut) ? FontWeight.bold : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (badgeText != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAdminConsoleConfirmation(
    BuildContext context,
    UserModel user,
  ) async {
    final confirmed = await showPortalSwitchConfirmation(
      context: context,
      toAdmin: true,
    );
    if (confirmed && context.mounted) {
      if (!Responsive.isDesktop(context)) {
        Navigator.pop(context);
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboardPage(user: user),
        ),
      );
    }
  }

  void _showSignOutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
}
