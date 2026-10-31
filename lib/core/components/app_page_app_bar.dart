import 'package:flutter/material.dart';

/// A reusable green top AppBar styled to match the Zim Herbs design system.
///
/// Features solid primary green background, white typography and icons,
/// and contextual back navigation (invoking [onBack] when supplied,
/// or [Navigator.pop] when a route can be popped).
///
/// Can be used seamlessly on both Admin Console and Public App screens.
class AppPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Widget? leading;
  final double elevation;
  final Color? shadowColor;
  final bool centerTitle;
  final double toolbarHeight;
  final IconThemeData? iconTheme;

  const AppPageAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.onBack,
    this.actions,
    this.leading,
    this.elevation = 2.0,
    this.shadowColor,
    this.centerTitle = false,
    this.toolbarHeight = kToolbarHeight,
    this.iconTheme,
  }) : assert(
          title != null || titleWidget != null,
          'Either title or titleWidget must be provided.',
        );

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canGoBack = onBack != null || Navigator.canPop(context);

    return AppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: elevation,
      shadowColor: shadowColor ?? theme.colorScheme.primary.withValues(alpha: 0.35),
      centerTitle: centerTitle,
      iconTheme: iconTheme ??
          IconThemeData(
            color: theme.colorScheme.onPrimary,
          ),
      actionsIconTheme: iconTheme ??
          IconThemeData(
            color: theme.colorScheme.onPrimary,
          ),
      leading: leading ??
          (canGoBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                  onPressed: () {
                    if (onBack != null) {
                      onBack!();
                    } else if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                )
              : null),
      title: titleWidget ??
          Text(
            title!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
      actions: actions,
    );
  }
}

