import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/settings/bloc/settings_bloc.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final rs = ResponsiveSize(context);

        return Scaffold(
          appBar:
              Responsive.isDesktop(context)
                  ? null
                  : AppBar(
                    toolbarHeight: 0,
                    elevation: 0,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(context, rs),
                const SizedBox(height: 16),
                _buildSection(
                  context: context,
                  title: 'Appearance',
                  rs: rs,
                  children: [
                    const SizedBox(height: 16),
                    _buildSliderSetting(
                      context: context,
                      icon: Icons.text_fields_rounded,
                      title: 'Font Scale',
                      value: state.fontScale,
                      min: 0.8,
                      max: 1.5,
                      divisions: 7,
                      label: '${(state.fontScale * 100).toInt()}%',
                      onChanged:
                          (val) => context.read<SettingsBloc>().add(
                            UpdateFontScale(val),
                          ),
                      rs: rs,
                      footer: 'Preview your reading experience below',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context: context,
                  title: 'Font Preview',
                  rs: rs,
                  children: [_buildPreviewCard(context, rs)],
                ),
                const SizedBox(height: 24),
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
      },
    );
  }

  Widget _buildHeader(BuildContext context, ResponsiveSize rs) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
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

  Widget _buildSliderSetting({
    required BuildContext context,
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
    required ResponsiveSize rs,
    String? footer,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: rs.icon * 0.7,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: rs.titleFont,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: rs.subtitleFont,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: theme.colorScheme.primary,
              onChanged: onChanged,
            ),
            if (footer != null) ...[
              const SizedBox(height: 8),
              Text(
                footer,
                style: TextStyle(
                  fontSize: rs.captionFont,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
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

  Widget _buildPreviewCard(BuildContext context, ResponsiveSize rs) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sample Title',
              style: TextStyle(
                fontSize: rs.titleFont,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is a sample description to demonstrate how the font-scaling affects your reading experience across the zim herbs application.',
              style: TextStyle(fontSize: rs.bodyFont, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Label Preview',
                style: TextStyle(fontSize: rs.labelFont, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
