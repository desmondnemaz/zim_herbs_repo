import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/components/app_page_app_bar.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    return Scaffold(
      appBar: Responsive.isDesktop(context)
          ? null
          : const AppPageAppBar(
              title: 'Settings',
            ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (Responsive.isDesktop(context)) ...[
              _buildHeader(context, rs),
              const SizedBox(height: 16),
            ],
            _buildSection(
              context: context,
              title: 'Information',
              rs: rs,
              children: [
                _buildAboutTile(
                  context: context,
                  icon: Icons.info_outline,
                  title: 'App Version',
                  trailing: 'v1.0.0',
                  rs: rs,
                ),
                _buildAboutTile(
                  context: context,
                  icon: Icons.policy_outlined,
                  title: 'Privacy Policy',
                  rs: rs,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ResponsiveSize rs) {
    return Row(
      children: [
        if (Navigator.canPop(context))
          InkWell(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            borderRadius: BorderRadius.circular(50),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.primary,
                size: rs.appBarIcon,
              ),
            ),
          ),
        const SizedBox(width: 8),
        Text(
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            fontSize: rs.appBarTitleFont,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required ResponsiveSize rs,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: rs.titleFont,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildAboutTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? trailing,
    required ResponsiveSize rs,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(fontSize: rs.bodyFont, fontWeight: FontWeight.w500),
      ),
      trailing:
          trailing != null
              ? Text(
                trailing,
                style: TextStyle(fontSize: rs.bodyFont, color: Colors.grey),
              )
              : const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
