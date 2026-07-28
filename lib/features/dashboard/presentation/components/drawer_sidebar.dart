
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';
import 'package:zim_herbs_repo/features/settings/presentation/settings_page.dart';
import 'package:zim_herbs_repo/features/notifications/presentation/notifications_page.dart';

class DrawerSideBar extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onToggle;

  const DrawerSideBar({
    super.key,
    this.isExpanded = true,
    this.onToggle,
  });

  @override
  State<DrawerSideBar> createState() => _DrawerSideBarState();
}

class _DrawerSideBarState extends State<DrawerSideBar> {
  String _activeRoute = "Dashboard";

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    if (isDesktop) {
      if (widget.isExpanded) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo image
              Row(
                children: [
                  Image.asset(
                    'assets/logo/logo.png',
                    height: 32,
                    width: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.grass,
                      size: 32,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "ZIM-HERBS",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              // Toggle button
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
                errorBuilder: (_, _, _) => Icon(
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
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.15),
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
            color: Theme.of(context)
                .colorScheme
                .onPrimary
                .withValues(alpha: 0.2),
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
                    Text(
                      "ZIM HERBS",
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "v1.0.0",
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.4),
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

    Widget content = SafeArea(
      child: Column(
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
                    isActive: _activeRoute == "Dashboard",
                    onTap: () =>
                        setState(() => _activeRoute = "Dashboard"),
                  ),
                  _buildMenuItem(
                    title: "Profile",
                    svgSrc: "assets/icons/menu_profile.svg",
                    isActive: _activeRoute == "Profile",
                    onTap: () =>
                        setState(() => _activeRoute = "Profile"),
                  ),
                  _buildMenuItem(
                    title: "Notifications",
                    icon: Icons.notifications_none,
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
        width: widget.isExpanded ? 250 : 70,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary, // #2E7D32
          borderRadius: BorderRadius.zero, // Sits completely flush top and left
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

  Widget _buildMenuItem({
    required String title,
    String? svgSrc,
    IconData? icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDesktop = Responsive.isDesktop(context);
    final isExpanded = !isDesktop || widget.isExpanded;

    if (!isExpanded) {
      final childWidget = svgSrc != null
          ? SvgPicture.asset(
              svgSrc,
              colorFilter: ColorFilter.mode(
                isActive
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                BlendMode.srcIn,
              ),
              height: 24,
            )
          : Icon(
              icon,
              color: isActive
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
              size: 24,
            );

      return Tooltip(
        message: title,
        preferBelow: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: InkWell(
            onTap: onTap,
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
              child: Center(child: childWidget),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: svgSrc != null
              ? SvgPicture.asset(
                  svgSrc,
                  colorFilter: ColorFilter.mode(
                    isActive
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                    BlendMode.srcIn,
                  ),
                  height: 24,
                )
              : Icon(
                  icon,
                  color: isActive
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                  size: 24,
                ),
          title: Text(
            title,
            style: TextStyle(
              color: isActive
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
