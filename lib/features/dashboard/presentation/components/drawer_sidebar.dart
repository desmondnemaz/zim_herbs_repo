import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import 'package:zim_herbs_repo/core/theme/spacing.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/settings/presentation/settings_page.dart';
import 'package:zim_herbs_repo/features/notifications/presentation/notifications_page.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/admin_dashboard_page.dart';


class DrawerSideBar extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onToggle;

  const DrawerSideBar({super.key, this.isExpanded = true, this.onToggle});

  @override
  State<DrawerSideBar> createState() => _DrawerSideBarState();
}

class _DrawerSideBarState extends State<DrawerSideBar> {
  String _activeRoute = "Dashboard";

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
    final isDesktop = Responsive.isDesktop(context);
    final showCollapsed = isDesktop && !widget.isExpanded;

    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            color: Theme.of(
              context,
            ).colorScheme.onPrimary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 8),
          if (showCollapsed)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage(
                  'assets/images/zimbabwe-flag-rounded.png',
                ),
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.transparent,
                        backgroundImage: AssetImage(
                          'assets/images/zimbabwe-flag-rounded.png',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "ZIM HERBS",
                        overflow: TextOverflow.clip,
                        softWrap: false,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "v1.0.0",
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
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
                  _buildMenuItem(
                    title: "Dashboard",
                    svgSrc: "assets/icons/menu_dashboard.svg",
                    iconColor: const Color(0xFF80CBC4),
                    isActive: _activeRoute == "Dashboard",
                    onTap: () => setState(() => _activeRoute = "Dashboard"),
                  ),
                  _buildMenuItem(
                    title: "Profile",
                    svgSrc: "assets/icons/menu_profile.svg",
                    iconColor: const Color(0xFF81C784),
                    isActive: _activeRoute == "Profile",
                    onTap: () => setState(() => _activeRoute = "Profile"),
                  ),
                  _buildMenuItem(
                    title: "Notifications",
                    icon: Icons.notifications_none,
                    iconColor: const Color(0xFFFFB74D),
                    isActive: _activeRoute == "Notifications",
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
                    svgSrc: "assets/icons/menu_setting.svg",
                    iconColor: const Color(0xFF64B5F6),
                    isActive: _activeRoute == "Settings",
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
                  Builder(
                    builder: (context) {
                      try {
                        final authState = context.watch<AuthCubit>().state;
                        if (authState is Authenticated && authState.user.role.isAdmin) {
                          return _buildMenuItem(
                            title: "Admin Console",
                            icon: Icons.admin_panel_settings,
                            iconColor: const Color(0xFFCE93D8),
                            isActive: false,
                            onTap: () {
                              if (!Responsive.isDesktop(context)) {
                                Navigator.pop(context);
                              }
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminDashboardPage(user: authState.user),
                                ),
                              );
                            },
                          );
                        }
                      } catch (_) {}
                      return const SizedBox.shrink();
                    },
                  ),
                  _buildMenuItem(
                    title: "Sign Out",
                    icon: Icons.logout_rounded,
                    isActive: false,
                    isSignOut: true,
                    onTap: () => _showSignOutConfirmation(context),
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
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final isDesktop = Responsive.isDesktop(context);
    final isExpanded = !isDesktop || widget.isExpanded;
    final accentColor = iconColor ?? Theme.of(context).colorScheme.secondary;

    final itemColor = isSignOut
        ? Colors.white
        : isActive
            ? accentColor
            : accentColor.withValues(alpha: 0.88);

    final tileBackground = isSignOut
        ? Colors.white.withValues(alpha: 0.12)
        : isActive
            ? accentColor.withValues(alpha: 0.22)
            : Colors.transparent;

    final textColor = isSignOut
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
        message: title,
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
              ],
            ),
          ),
        ),
      ),
    );
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
