import 'package:flutter/material.dart';

/// Data class representing an item within [AppBadgedTabBar].
class BadgedTabItem {
  final String label;
  final IconData icon;
  final int? count;
  final Color? badgeColor;

  const BadgedTabItem({
    required this.label,
    required this.icon,
    this.count,
    this.badgeColor,
  });
}

/// A reusable segmented TabBar container with optional count badges and a customizable background (defaulting to white).
class AppBadgedTabBar extends StatelessWidget {
  final TabController controller;
  final List<BadgedTabItem> tabs;
  final Color backgroundColor;
  final EdgeInsetsGeometry? margin;

  const AppBadgedTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.backgroundColor = Colors.white,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: TabBar(
        controller: controller,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor:
            theme.colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 2.5,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        tabs: tabs.map((item) => _buildTab(item, theme)).toList(),
      ),
    );
  }

  Widget _buildTab(BadgedTabItem item, ThemeData theme) {
    return Tab(
      height: 38,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 15),
          const SizedBox(width: 5),
          Text(item.label, style: const TextStyle(fontSize: 12.5)),
          if (item.count != null) ...[
            const SizedBox(width: 5),
            _buildCountBadge(
                item.count!, item.badgeColor ?? const Color(0xFFD97706)),
          ],
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, Color color) {
    final isMuted = count == 0;
    return Container(
      height: 18,
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isMuted ? Colors.grey.shade300 : color,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: isMuted ? Colors.grey.shade700 : Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
    );
  }
}
