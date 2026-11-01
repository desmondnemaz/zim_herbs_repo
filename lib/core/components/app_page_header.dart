import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';

export 'app_page_app_bar.dart';

/// A modern surface header banner displayed below the AppBar or at the top of page bodies.
///
/// Features a domain-specific accent icon, bold title, subtitle description,
/// and an inline back button for desktop viewport where the mobile AppBar is suppressed.
class AppPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;

  const AppPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onBack,
    this.trailing,
    this.iconColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rs = ResponsiveSize(context);
    final canGoBack = onBack != null || Navigator.canPop(context);
    final isDesktop = Responsive.isDesktop(context);

    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: rs.defaultPadding,
            vertical: rs.defaultPadding * 0.75,
          ),
      color: theme.scaffoldBackgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // On desktop (where mobile AppBar is not present), show back button if canGoBack
          if (canGoBack && isDesktop) ...[
            InkWell(
              onTap: () {
                if (onBack != null) {
                  onBack!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: rs.defaultPadding),
          ],
          Icon(
            icon,
            color: iconColor ?? theme.colorScheme.primary,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    fontSize: rs.titleFont * 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
