import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/admin/condition_management/presentation/components/add_edit_condition_dialog.dart';
import 'package:zim_herbs_repo/features/admin/herb_management/presentation/add_edit_herb_page.dart';
import 'package:zim_herbs_repo/features/admin/treatment_management/presentation/add_edit_treatment_page.dart';

/// The Overview landing screen for admin — mirrors the rich content style
/// of the customer dashboard with a welcome banner, stat cards and quick actions.
class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rs = ResponsiveSize(context);
    final isDesktop = Responsive.isDesktop(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(rs.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Welcome Banner ────────────────────────────────────────────────
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final name =
                  state is Authenticated ? state.user.name : 'Administrator';
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $name 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Here's a live snapshot of the Zim Herbs system.",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // ─── Section: System Stats ─────────────────────────────────────────
          Text(
            'System Overview',
            style: TextStyle(
              fontSize: rs.titleFont * 1.1,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: isDesktop ? 4 : (Responsive.isTablet(context) ? 2 : 2),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isDesktop ? 2.0 : 1.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _StatCard(title: 'Total Herbs', value: '42', icon: Icons.local_florist, color: Colors.green),
              _StatCard(title: 'Conditions', value: '18', icon: Icons.sick_outlined, color: Colors.teal),
              _StatCard(title: 'Treatments', value: '35', icon: Icons.healing, color: Colors.blue),
              _StatCard(title: 'Store Orders', value: '124', icon: Icons.shopping_bag_outlined, color: Colors.orange),
              _StatCard(title: 'Consultations', value: '8', icon: Icons.medical_services_outlined, color: Colors.purple),
              _StatCard(title: 'Users', value: '2,104', icon: Icons.people_alt_outlined, color: Colors.blueGrey),
              _StatCard(title: 'Pending Reviews', value: '7', icon: Icons.rate_review_outlined, color: Colors.amber),
              _StatCard(title: 'AI Interactions', value: '98', icon: Icons.smart_toy_outlined, color: Colors.indigo),
            ],
          ),

          const SizedBox(height: 32),

          // ─── Section: Quick Actions ────────────────────────────────────────
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: rs.titleFont * 1.1,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: isDesktop ? 4 : (Responsive.isTablet(context) ? 2 : 2),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isDesktop ? 1.9 : 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _QuickActionCard(
                title: 'Add Herb',
                icon: Icons.local_florist,
                color: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditHerbPage()),
                ),
              ),
              _QuickActionCard(
                title: 'Add Treatment',
                icon: Icons.healing,
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditTreatmentPage()),
                ),
              ),
              _QuickActionCard(
                title: 'Add Condition',
                icon: Icons.medical_information,
                color: Colors.teal,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => AddEditConditionDialog(
                    onSave: (c) => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Condition saved: ${c.name}')),
                    ),
                  ),
                ),
              ),
              _QuickActionCard(
                title: 'View Reports',
                icon: Icons.bar_chart,
                color: Colors.orange,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reports module coming soon!')),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    title,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Action Card ─────────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.secondary.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.secondary, size: 30),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
