import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  // Required Platforms
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;
  const Responsive({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  static bool isMobile(BuildContext contex) =>
      MediaQuery.of(contex).size.width < 850;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < 1100 &&
      MediaQuery.of(context).size.width >= 850;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 1100;

  @override
  Widget build(BuildContext context) {
    // Declaring _SIZE VARIABLE(The code will auto detect screen size using MediaQuery Function)
    final Size size = MediaQuery.of(context).size;

    //If our widht is more than 1100 we consider it as Desktop
    if (size.width > 1100) {
      return desktop;

      //If our screen widht is bettween 850 && 1100 we consider it as a tablet
    } else if (size.width > 600 && size.width < 1024) {
      return tablet;
    }
    // or less is a mobile screen
    else {
      return mobile;
    }
  }
}
