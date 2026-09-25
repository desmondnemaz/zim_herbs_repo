import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/admin/herb_management/presentation/add_edit_herb_page.dart';
import 'package:zim_herbs_repo/features/admin/remedy_management/presentation/add_edit_remedy_page.dart';

/// The Overview landing screen for admin with live data from Supabase.
class AdminOverviewScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const AdminOverviewScreen({super.key, this.onNavigate});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  int _herbsCount = 0;
  int _conditionsCount = 0;
  int _remediesCount = 0;
  int _pendingReviewsCount = 0;
  int _bodyPartsCount = 0;
  int _usersCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveStats();
  }

  Future<void> _loadLiveStats() async {
    try {
      final results = await Future.wait([
        _client.from('herbs').count(CountOption.exact),
        _client.from('conditions').count(CountOption.exact),
        _client.from('remedies').count(CountOption.exact),
        _client
            .from('remedies')
            .count(CountOption.exact)
            .eq('is_approved', false),
        _client.from('body_parts').count(CountOption.exact),
        _client.from('user_profiles').count(CountOption.exact),
      ]);

      if (mounted) {
        setState(() {
          _herbsCount = results[0];
          _conditionsCount = results[1];
          _remediesCount = results[2];
          _pendingReviewsCount = results[3];
          _bodyPartsCount = results[4];
          _usersCount = results[5];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
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
                            "Here's a live overview of Zim Herbs & HerbCircle platform.",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Refresh live stats',
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _loadLiveStats();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // ─── Section: System Stats ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Overview',
                style: TextStyle(
                  fontSize: rs.titleFont * 1.1,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount:
                isDesktop ? 4 : (Responsive.isTablet(context) ? 2 : 2),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isDesktop ? 2.0 : 1.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCard(
                title: 'Total Herbs',
                value: '$_herbsCount',
                icon: Icons.local_florist,
                color: Colors.green,
                onTap: () => widget.onNavigate?.call(1),
              ),
              _StatCard(
                title: 'Conditions',
                value: '$_conditionsCount',
                icon: Icons.sick_outlined,
                color: Colors.teal,
                onTap: () => widget.onNavigate?.call(2),
              ),
              _StatCard(
                title: 'Remedies',
                value: '$_remediesCount',
                icon: Icons.healing,
                color: Colors.blue,
                onTap: () => widget.onNavigate?.call(3),
              ),
              _StatCard(
                title: 'Pending Reviews',
                value: '$_pendingReviewsCount',
                icon: Icons.rate_review_outlined,
                color: _pendingReviewsCount > 0 ? Colors.amber : Colors.grey,
                onTap: () => widget.onNavigate?.call(3),
              ),
              _StatCard(
                title: 'Body Parts',
                value: '$_bodyPartsCount',
                icon: Icons.accessibility_new,
                color: Colors.purple,
                onTap: () => widget.onNavigate?.call(2),
              ),
              _StatCard(
                title: 'Registered Users',
                value: '$_usersCount',
                icon: Icons.people_alt_outlined,
                color: Colors.blueGrey,
                onTap: () => widget.onNavigate?.call(5),
              ),
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
            crossAxisCount:
                isDesktop ? 4 : (Responsive.isTablet(context) ? 2 : 2),
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
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddEditHerbPage()),
                  );
                  _loadLiveStats();
                },
              ),
              _QuickActionCard(
                title: 'Add Remedy',
                icon: Icons.healing,
                color: Colors.blue,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddEditRemedyPage()),
                  );
                  _loadLiveStats();
                },
              ),
              _QuickActionCard(
                title: 'Moderate HerbCircle',
                icon: Icons.verified_user_outlined,
                color: Colors.amber,
                onTap: () => widget.onNavigate?.call(3),
              ),
              _QuickActionCard(
                title: 'User Management',
                icon: Icons.manage_accounts_outlined,
                color: Colors.teal,
                onTap: () => widget.onNavigate?.call(5),
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
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: rs.icon * 0.9),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: rs.titleFont * 1.05,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: rs.bodyFont * 0.85,
                      color: Colors.grey.shade600,
                    ),
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
    final rs = ResponsiveSize(context);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: rs.icon * 0.85),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: rs.subtitleFont,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
