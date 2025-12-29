import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';
import 'package:zim_herbs_repo/features/settings/presentation/settings_page.dart';
import 'package:zim_herbs_repo/core/presentation/widgets/zimbabwe_widgets.dart';

class DrawerSideBar extends StatefulWidget {
  const DrawerSideBar({super.key});

  @override
  State<DrawerSideBar> createState() => _DrawerSideBarState();
}

class _DrawerSideBarState extends State<DrawerSideBar> {
  String _activeRoute = "Dashboard";

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: 0,
      child: ZimbabweWorkBackground(
        patternColor: Colors.white.withValues(alpha: 0.05),
        child: SafeArea(
          child: Column(
            children: [
              // Drawer Header / Logo
              Padding(
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
              ),

              // Menu Items
              _buildMenuItem(
                title: "Dashboard",
                svgSrc: "assets/icons/menu_dashboard.svg",
                isActive: _activeRoute == "Dashboard",
                onTap: () => setState(() => _activeRoute = "Dashboard"),
              ),
              _buildMenuItem(
                title: "Profile",
                svgSrc: "assets/icons/menu_profile.svg",
                isActive: _activeRoute == "Profile",
                onTap: () => setState(() => _activeRoute = "Profile"),
              ),
              _buildMenuItem(
                title: "Settings",
                svgSrc: "assets/icons/menu_setting.svg",
                isActive: _activeRoute == "Settings",
                onTap: () {
                  if (!Responsive.isDesktop(context)) {
                    Navigator.pop(context); // Close drawer only on mobile
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
              ),

              const Spacer(),

              // Footer
              Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  children: [
                    Divider(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.transparent,
                            backgroundImage: const AssetImage(
                              'assets/images/zimbabwe-flag-rounded.png',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "ZIM HERBS",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    String? svgSrc,
    IconData? icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color:
              isActive
                  ? Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading:
              svgSrc != null
                  ? SvgPicture.asset(
                    svgSrc,
                    colorFilter: ColorFilter.mode(
                      isActive
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.7),
                      BlendMode.srcIn,
                    ),
                    height: 24,
                  )
                  : Icon(
                    icon,
                    color:
                        isActive
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.7),
                    size: 24,
                  ),
          title: Text(
            title,
            style: TextStyle(
              color:
                  isActive
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.8),
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
