import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/coming_soon.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/menu_section.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/notifications_section.dart';
import 'package:zim_herbs_repo/features/herbs/presentation/herbs_list.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';
import 'package:zim_herbs_repo/theme/light_mode.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

class DashboardScreen extends StatelessWidget {

  final VoidCallback toogleDashbordSideBar;

  const DashboardScreen({super.key, required this.toogleDashbordSideBar});

  @override
  Widget build(BuildContext context) {
    // Sizing
    final rs = ResponsiveSize(context);

    // Example data for multiple cards with icons
    final List<Map<String, dynamic>> dashboardCards = [
      {
        'icon': Icons.local_florist,
        'title': 'Herbs',
        'subtitle': '(A - Z)',
        'page': HerbsList(),
      },
      {
        'icon': Icons.healing,
        'title': 'Remedies',
        'subtitle': '(By condition)',
        'page': ComingSoonPage(),
      },
      {
        'icon': Icons.groups,
        'title': 'Practioneers',
        'subtitle': '(Licensed by MoHCC)',
        'page': ComingSoonPage(),
      },
      {
        'icon': Icons.psychology_alt,
        'title': 'Knowledge',
        'subtitle': '(Resources)',
        'page': ComingSoonPage(),
      },
      {
        'icon': Icons.lightbulb_outline,
        'title': 'Innovation',
        'subtitle': '(Contributions)',
        'page': ComingSoonPage(),
      },
    ];

    return SafeArea(
      // Whole Dashboard
      child: Container(
        padding: const EdgeInsets.all(5 / 2),
        decoration: BoxDecoration(color: pharmacyTheme.colorScheme.primary),

        child: Column(
          children: [
            // ================= Sticky Header / Navbar =================
            Padding(
              padding: const EdgeInsets.all(defaultPadding / 2),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: pharmacyTheme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    width: 2,
                    color: pharmacyTheme.colorScheme.secondary,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: toogleDashbordSideBar,
                          child: Icon(
                            Icons.menu,
                            size: rs.appBarIcon,
                            color: pharmacyTheme.colorScheme.onPrimary,
                          ),
                        ),
                        SizedBox(width: defaultPadding),
                        // Title
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: pharmacyTheme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: pharmacyTheme.colorScheme.primary,
                            ),
                          ),

                          child: Text(
                            "ZIM Herbal Pharmacy",
                            style: TextStyle(
                              fontSize: rs.appBarTitleFont,
                              fontWeight: FontWeight.w900,
                              color: pharmacyTheme.colorScheme.secondary,
                            ),
                          ),
                        ),

                        Icon(
                          Icons.grass,
                          size: rs.appBarIcon,
                          color: pharmacyTheme.colorScheme.secondary,
                        ),
                      ],
                    ),
                    const Spacer(flex: 2),
                    if (!Responsive.isMobile(context))
                      // Profile section
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: pharmacyTheme.colorScheme.secondary,
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(10),
                            topLeft: Radius.circular(10),
                          ),
                          border: Border.all(
                            color: pharmacyTheme.colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: rs.appBarIcon,
                              color: pharmacyTheme.colorScheme.primary,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: defaultPadding,
                              ),
                              child: Text(
                                "Desmond",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: pharmacyTheme.colorScheme.onSecondary,
                                  fontSize: rs.appBarSubtitleFont,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_outlined,
                              color: pharmacyTheme.colorScheme.onSecondary,
                              size: rs.appBarIcon,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ================= Scrollable Body =================
            Expanded(
              child: SingleChildScrollView(
                
                child:
                    Responsive.isMobile(context)
                        ? Container(
                          padding: EdgeInsets.only(
                            right: defaultPadding,
                            top: defaultPadding,
                            bottom: 50,
                            left: defaultPadding,
                          ),
                          decoration: BoxDecoration(
                            color: pharmacyTheme.colorScheme.surface,
                            borderRadius: const BorderRadius.only(
                            ),
                          ),
                          child: Column(
                            // On mobile → stack vertically
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ===== Left (Menu) =====
                              MenuSection(dashboardCards: dashboardCards),

                              SizedBox(height: defaultPadding),

                              // ===== Right (Notifications) =====
                              const NotificationsSection(),
                            ],
                          ),
                        )

                        // Else on Desktop View
                        : Container(
                          padding: EdgeInsets.only(
                            right: defaultPadding,
                            top: defaultPadding,
                            bottom: 950,
                            left: defaultPadding,
                          ),
                          decoration: BoxDecoration(
                            color: pharmacyTheme.colorScheme.surface,
                          ),

                          child: Row(
                            // On desktop/tablet → side by side
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: MenuSection(
                                  dashboardCards: dashboardCards,
                                ),
                              ),
                              SizedBox(width: defaultPadding),
                              Expanded(
                                flex: 2,
                                child: const NotificationsSection(),
                              ),
                            ],
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
