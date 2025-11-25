//=======================Left Menu Panel===============================
import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/theme/light_mode.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

class MenuSection extends StatelessWidget {
  const MenuSection({
    super.key,
    required List<Map<String, dynamic>> dashboardCards,
  }) : _dashboardCards = dashboardCards;

  final List<Map<String, dynamic>> _dashboardCards;

  @override
  Widget build(BuildContext context) {
    // Sizing
    final rs = ResponsiveSize(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Menu",
          style: TextStyle(fontSize: rs.titleFont, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: defaultPadding),

        // ====== Grid Menu Section ======
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _dashboardCards.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = _dashboardCards[index];
            return _DashboardCard(
              icon: item['icon'],
              title: item['title'],
              subtitle: item['subtitle'],
              page: item['page'],
            );
          },
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    // detect device type
    final rs = ResponsiveSize(context);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: pharmacyTheme.colorScheme.secondary,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(0),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(10),
            topLeft: Radius.circular(10),
          ),
          boxShadow: [
            BoxShadow(
              color: pharmacyTheme.colorScheme.onSecondary,
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // <- important
            children: [
              Icon(
                icon,
                color: pharmacyTheme.colorScheme.primary,
                size: rs.icon,
              ),
              const SizedBox(height: 5),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: rs.titleFont,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: rs.subtitleFont,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
