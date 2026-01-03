import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/conditions/presentation/condition_list.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/coming_soon.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/menu_section.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/notifications_section.dart';
import 'package:zim_herbs_repo/features/herbs/presentation/herbs_list.dart';
import 'package:zim_herbs_repo/features/treatments/presentation/treatments_list.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback toogleDashbordSideBar;

  const DashboardScreen({super.key, required this.toogleDashbordSideBar});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dashboardCards = [
      {
        'icon': Icons.local_florist,
        'title': 'Herbs',
        'subtitle': '(A - Z)',
        'page': const HerbsList(),
      },
      {
        'icon': Icons.healing,
        'title': 'Treatments',
        'subtitle': '(By condition)',
        'page': const TreatmentsList(),
      },
      {
        'icon': Icons.sick_outlined,
        'title': 'Diseases',
        'subtitle': '(A - Z)',
        'page': const ConditionsListPage(),
      },
      {
        'icon': Icons.groups,
        'title': 'Practioneers',
        'subtitle': '(Licensed by MoHCC)',
        'page': const ComingSoonPage(),
      },
      {
        'icon': Icons.psychology_alt,
        'title': 'Knowledge',
        'subtitle': '(Resources)',
        'page': const ComingSoonPage(),
      },
      {
        'icon': Icons.lightbulb_outline,
        'title': 'Innovation',
        'subtitle': '(Contributions)',
        'page': const ComingSoonPage(),
      },
    ];

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          children: [
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
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MenuSection(dashboardCards: dashboardCards),
                              const SizedBox(height: defaultPadding),
                              const NotificationsSection(),
                            ],
                          ),
                        )
                        : Container(
                          padding: EdgeInsets.all(defaultPadding),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: MenuSection(
                                  dashboardCards: dashboardCards,
                                ),
                              ),
                              const SizedBox(width: defaultPadding),
                              const Expanded(
                                flex: 2,
                                child: NotificationsSection(),
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
