

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zim_herbs_repo/theme/light_mode.dart';

class DrawerSideBar extends StatelessWidget {
  const DrawerSideBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
              // SIZE = 1/6 OF THE TOTAL SCREEN
      flex: 1,
      child: Drawer(
        // backgroundColor: pharmacyTheme.colorScheme.secondary,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DrawerHeader(
                child: Icon(
                  Icons.grass,
                  size: 100,
                  color: pharmacyTheme.colorScheme.primary,
                ),
              ),
              DrawerListTile(
                title: "Dashboard",
                svgSrc: "assets/icons/menu_dashboard.svg",
                onTap: () {},
              ),
              DrawerListTile(
                title: "Profile",
                svgSrc: "assets/icons/menu_profile.svg",
                onTap: () {},
              ),
              
              DrawerListTile(
                title: "Settings",
                svgSrc: "assets/icons/menu_setting.svg",
                onTap: () {},
              ),
              // DrawerListTile(
              //   title: 'Signout',
              //   icon: Icons.logout_rounded,
              //onTap:() {},
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerListTile extends StatelessWidget {
  final String title;
  final String svgSrc;
  final VoidCallback? onTap;

  const DrawerListTile({
    super.key,
    required this.title,
    required this.svgSrc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: pharmacyTheme.colorScheme.primary,
        ),
      ),
      leading: SvgPicture.asset(
        svgSrc,
        colorFilter: ColorFilter.mode(
          pharmacyTheme.colorScheme.primary,
          BlendMode.srcIn,
        ),
        height: 16,
      ),

      onTap: onTap,
    );
  }
}
