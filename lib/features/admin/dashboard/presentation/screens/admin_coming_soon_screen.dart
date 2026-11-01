import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';

/// Placeholder shown for admin sections that are not yet implemented.
class AdminComingSoonScreen extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const AdminComingSoonScreen({
    super.key,
    required this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = title == 'Reports'
        ? Icons.assessment_rounded
        : title == 'Analytics'
            ? Icons.analytics_rounded
            : Icons.dashboard_customize_rounded;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: title,
              subtitle: 'System administration and reporting',
              icon: icon,
              onBack: onBack,
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.construction_outlined,
                        size: 64,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This section is under active development.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check back soon!',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
