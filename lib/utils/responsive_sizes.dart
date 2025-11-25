import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';

class ResponsiveSize {
  final BuildContext context;

  ResponsiveSize(this.context);

  // ------------------- Device detection -------------------
  bool get isMobile => Responsive.isMobile(context);
  bool get isTablet => Responsive.isTablet(context);
  bool get isDesktop => Responsive.isDesktop(context);

  // Generic helper
  T pick<T>({required T mobile, required T tablet, required T desktop}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }

  // ------------------- AppBar / Header -------------------
  double get appBarIcon => pick(mobile: 20, tablet: 26, desktop: 32);
  double get appBarPadding => pick(mobile: 8, tablet: 12, desktop: 16);
  double get appBarTitleFont => pick(mobile: 16, tablet: 20, desktop: 24);
  double get appBarSubtitleFont => pick(mobile: 12, tablet: 14, desktop: 16);

  // ------------------- Cards / Menu Grid -------------------
  double get icon => pick(mobile: 32, tablet: 44, desktop: 56);
  double get padding => pick(mobile: 10, tablet: 16, desktop: 20);
  double get titleFont => pick(mobile: 13, tablet: 16, desktop: 18);
  double get subtitleFont => pick(mobile: 10, tablet: 12, desktop: 14);
  int get gridCount => pick(mobile: 1, tablet: 2, desktop: 4);
  double get gridSpacing => pick(mobile: 10, tablet: 16, desktop: 20);
  double get cardAspectRatio => pick(mobile: 1.2, tablet: 1.0, desktop: 1.0);

  // ------------------- Notifications / Side Panel -------------------
  double get panelPadding => pick(mobile: 8, tablet: 12, desktop: 16);
  double get panelTitleFont => pick(mobile: 14, tablet: 16, desktop: 18);
  double get panelItemFont => pick(mobile: 12, tablet: 14, desktop: 16);
  double get panelIconSize => pick(mobile: 16, tablet: 20, desktop: 24);

  // ------------------- Global Layout / Spacing -------------------
  double get defaultPadding => pick(mobile: 10, tablet: 16, desktop: 20);
  double get rowSpacing => pick(mobile: 8, tablet: 12, desktop: 16);
  double get columnSpacing => pick(mobile: 8, tablet: 12, desktop: 16);

  // ------------------- Drawer / Navigation -------------------
  double get drawerWidth => pick(mobile: 200, tablet: 250, desktop: 300);

  // ------------------- Buttons / FAB -------------------
  double get buttonFont => pick(mobile: 12, tablet: 14, desktop: 16);
  double get fabSize => pick(mobile: 40, tablet: 50, desktop: 60);

  // ------------------- Border Radius -------------------
  double get borderRadius => pick(mobile: 8, tablet: 10, desktop: 12);
}
