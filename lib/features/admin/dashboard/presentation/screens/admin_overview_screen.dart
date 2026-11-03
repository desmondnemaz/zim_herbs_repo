import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';
import 'package:zim_herbs_repo/features/admin/herb_management/presentation/add_edit_herb_page.dart';
import 'package:zim_herbs_repo/features/admin/herb_management/presentation/herb_import_page.dart';
import 'package:zim_herbs_repo/features/admin/remedy_management/presentation/add_edit_remedy_page.dart';
import 'package:zim_herbs_repo/features/admin/ailment_management/presentation/components/add_edit_ailment_dialog.dart';
import 'package:zim_herbs_repo/features/admin/ailment_management/presentation/body_parts_page.dart';
import 'package:zim_herbs_repo/features/repository/ailments/presentation/cubit/ailment_cubit.dart';

import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';

/// The Overview landing screen for admin with live data from Supabase.
class AdminOverviewScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  final UserModel? user;

  const AdminOverviewScreen({super.key, this.onNavigate, this.user});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  int _herbsCount = 0;
  int _conditionsCount = 0;
  int _remediesCount = 0;
  int _pendingReviewsCount = 0;
  int _usersCount = 0;
  bool _isLoading = true;
  Failure? _errorFailure;

  @override
  void initState() {
    super.initState();
    _loadLiveStats();
  }

  Future<void> _loadLiveStats() async {
    setState(() {
      _isLoading = true;
      _errorFailure = null;
    });

    try {
      int ailmentsCount = 0;
      try {
        ailmentsCount = await _client.from('ailments').count(CountOption.exact);
      } catch (_) {
        ailmentsCount =
            await _client.from('conditions').count(CountOption.exact);
      }

      final results = await Future.wait([
        _client.from('herbs').count(CountOption.exact),
        _client.from('remedies').count(CountOption.exact),
        _client
            .from('remedies')
            .count(CountOption.exact)
            .neq('validation_status', 'published'),
        _client
            .from('herbs')
            .count(CountOption.exact)
            .neq('validation_status', 'published'),
        _client.from('user_profiles').count(CountOption.exact),
      ]);

      if (mounted) {
        setState(() {
          _herbsCount = results[0];
          _conditionsCount = ailmentsCount;
          _remediesCount = results[1];
          _pendingReviewsCount = results[2] + results[3];
          _usersCount = results[4];
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _errorFailure = ErrorHandler.handle(e, stackTrace);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    return Container(
      color: const Color(0xFFF3F8F2),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(rs.defaultPadding),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
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
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2E7D32),
                            Color(0xFF1B5E20),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
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
                if (_errorFailure != null) ...[
                  const SizedBox(height: 16),
                  AppErrorView.banner(
                    failure: _errorFailure,
                    title: 'Live Stats Unavailable',
                    actionLabel: 'Retry',
                    onAction: _loadLiveStats,
                  ),
                ],
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
                        color: const Color(0xFF1B5E20),
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

                // Statistic Cards (Constrained & Uniform Size)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableWidth = constraints.maxWidth;
                    if (availableWidth <= 0) return const SizedBox.shrink();
                    const double spacing = 12.0;
                    const double cardHeight = 84.0;

                    final herbsCard = _StatCard(
                      title: 'Herbs',
                      value: '$_herbsCount',
                      icon: Icons.local_florist_rounded,
                      color: const Color(0xFF22633C),
                      onTap: () => widget.onNavigate?.call(2),
                    );

                    final conditionsCard = _StatCard(
                      title: 'Ailments',
                      value: '$_conditionsCount',
                      icon: Icons.monitor_heart_outlined,
                      color: const Color(0xFF106F74),
                      onTap: () => widget.onNavigate?.call(3),
                    );

                    final remediesCard = _StatCard(
                      title: 'Remedies',
                      value: '$_remediesCount',
                      icon: Icons.healing_outlined,
                      color: const Color(0xFF295CA2),
                      onTap: () => widget.onNavigate?.call(4),
                    );

                    final pendingReviewsCard = _StatCard(
                      title: 'Pending Reviews',
                      value: '$_pendingReviewsCount',
                      icon: Icons.chat_bubble_outline_rounded,
                      color: const Color(0xFFA85B18),
                      onTap: () => widget.onNavigate?.call(1),
                    );

                    final usersCard = _StatCard(
                      title: 'Users',
                      value: '$_usersCount',
                      icon: Icons.people_outline_rounded,
                      color: const Color(0xFF684B8A),
                      onTap: () => widget.onNavigate?.call(6),
                    );

                    // On mobile: 2-column layout for standard cards with Pending Reviews spanning full width
                    if (rs.isMobile || availableWidth < 600) {
                      final double colWidth = ((availableWidth - spacing) / 2).floorToDouble();

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              SizedBox(width: colWidth, height: cardHeight, child: herbsCard),
                              const SizedBox(width: spacing),
                              SizedBox(width: colWidth, height: cardHeight, child: conditionsCard),
                            ],
                          ),
                          const SizedBox(height: spacing),
                          Row(
                            children: [
                              SizedBox(width: colWidth, height: cardHeight, child: remediesCard),
                              const SizedBox(width: spacing),
                              SizedBox(width: colWidth, height: cardHeight, child: usersCard),
                            ],
                          ),
                          const SizedBox(height: spacing),
                          SizedBox(
                            width: double.infinity,
                            height: cardHeight,
                            child: pendingReviewsCard,
                          ),
                        ],
                      );
                    }

                    // On tablet & desktop viewports: dynamic wrapping
                    final int count = (availableWidth / 220).floor().clamp(1, 5);
                    final double cardWidth =
                        ((availableWidth - (spacing * (count - 1))) / count)
                            .floorToDouble();

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        SizedBox(width: cardWidth, height: cardHeight, child: herbsCard),
                        SizedBox(width: cardWidth, height: cardHeight, child: conditionsCard),
                        SizedBox(width: cardWidth, height: cardHeight, child: remediesCard),
                        SizedBox(width: cardWidth, height: cardHeight, child: pendingReviewsCard),
                        SizedBox(width: cardWidth, height: cardHeight, child: usersCard),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // ─── Section: Quick Actions ────────────────────────────────────────
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: rs.titleFont * 1.1,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableWidth = constraints.maxWidth;
                    if (availableWidth <= 0) return const SizedBox.shrink();
                    final int count = (availableWidth / 220).floor().clamp(1, 5);
                    const double spacing = 12.0;
                    final double cardWidth =
                        ((availableWidth - (spacing * (count - 1))) / count)
                            .floorToDouble();
                    const double cardHeight = 84.0;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _QuickActionCard(
                            title: 'Add Herb',
                            icon: Icons.local_florist_rounded,
                            color: const Color(0xFF22633C),
                            pastelBackground: const Color(0xFFEAF5EB),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AddEditHerbPage()),
                              );
                              _loadLiveStats();
                            },
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _QuickActionCard(
                            title: 'Import Excel',
                            icon: Icons.table_chart_rounded,
                            color: const Color(0xFF15803D),
                            pastelBackground: const Color(0xFFF0FDF4),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const HerbImportPage()),
                              );
                              _loadLiveStats();
                            },
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _QuickActionCard(
                            title: 'Add Ailment',
                            icon: Icons.monitor_heart_outlined,
                            color: const Color(0xFF106F74),
                            pastelBackground: const Color(0xFFE6F5F5),
                            onTap: () async {
                              await showDialog(
                                context: context,
                                builder: (dialogContext) => AddEditAilmentDialog(
                                  onSave: (newAilmentModel) async {
                                    final newAilment = newAilmentModel.toEntity();
                                    final bodyPartIds = newAilmentModel.bodyParts
                                        .map((bp) => bp.id)
                                        .toList();
                                    await context.read<AilmentCubit>().createAilment(
                                      newAilment,
                                      bodyPartIds: bodyPartIds,
                                    );
                                    _loadLiveStats();
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _QuickActionCard(
                            title: 'Add Remedy',
                            icon: Icons.healing_outlined,
                            color: const Color(0xFF295CA2),
                            pastelBackground: const Color(0xFFEBF3FC),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AddEditRemedyPage()),
                              );
                              _loadLiveStats();
                            },
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _QuickActionCard(
                            title: 'Body Parts',
                            icon: Icons.accessibility_new_rounded,
                            color: const Color(0xFF0F766E),
                            pastelBackground: const Color(0xFFE6F4F2),
                            onTap: () async {
                              if (widget.onNavigate != null) {
                                widget.onNavigate!(9);
                              } else {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BodyPartsPage(),
                                  ),
                                );
                                _loadLiveStats();
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
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
    // Use dark charcoal for numerical values where contrast permits (WCAG luminance >= 0.45),
    // otherwise fallback to white on darker saturated backgrounds to ensure optimal contrast.
    final bool contrastPermits = color.computeLuminance() >= 0.45;
    const Color darkCharcoal = Color(0xFF1E293B);
    final Color numericalColor = contrastPermits ? darkCharcoal : Colors.white;
    final Color iconColor = contrastPermits ? darkCharcoal : Colors.white;
    final Color titleColor = contrastPermits
        ? darkCharcoal.withValues(alpha: 0.85)
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: contrastPermits
                  ? color.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.16),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: numericalColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
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
  final Color? pastelBackground;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    this.pastelBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = pastelBackground ?? color.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    height: 1.2,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: color.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
