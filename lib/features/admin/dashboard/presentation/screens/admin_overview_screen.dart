import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:zim_herbs_repo/core/utils/enums.dart';
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
import 'package:zim_herbs_repo/core/services/user_presence_service.dart';

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

  bool _isAnalyticsExpanded = true;
  bool _isLoadingAnalytics = false;
  bool _hasLoadedAnalytics = false;

  int _analyticsTotalHerbs = 0;
  int _analyticsApprovedHerbs = 0;
  int _analyticsTotalRemedies = 0;
  int _analyticsApprovedRemedies = 0;
  int _analyticsTotalAilments = 0;

  Map<String, int> _analyticsGrowthHabits = {};
  Map<String, int> _analyticsExoticStatuses = {};
  Map<String, int> _analyticsTopFamilies = {};
  Map<String, int> _analyticsAilmentCategories = {};

  @override
  void initState() {
    super.initState();
    _loadLiveStats();
    _loadAnalyticsData();
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

  Future<void> _loadAnalyticsData() async {
    if (_hasLoadedAnalytics && !_isLoadingAnalytics) return;
    setState(() => _isLoadingAnalytics = true);

    try {
      List<Map<String, dynamic>> ailmentsData = [];
      try {
        final res = await _client.from('ailments').select();
        ailmentsData = List<Map<String, dynamic>>.from(res);
      } catch (_) {
        try {
          final res = await _client.from('conditions').select();
          ailmentsData = List<Map<String, dynamic>>.from(res);
        } catch (_) {}
      }

      final results = await Future.wait([
        _client
            .from('herbs')
            .select()
            .then((v) => List<Map<String, dynamic>>.from(v))
            .catchError((_) => <Map<String, dynamic>>[]),
        _client
            .from('remedies')
            .select()
            .then((v) => List<Map<String, dynamic>>.from(v))
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);

      final herbs = results[0];
      final remedies = results[1];

      final habits = <String, int>{};
      final origins = <String, int>{};
      final families = <String, int>{};
      int approvedH = 0;

      for (final h in herbs) {
        final status = RecordValidationStatus.fromString(
          h['validation_status'] as String?,
        );
        if (status.isPublished) approvedH++;

        final habit = (h['growth_habit'] ?? '').toString().trim();
        final habitKey = habit.isEmpty ? 'Unspecified' : habit;
        habits[habitKey] = (habits[habitKey] ?? 0) + 1;

        final origin = (h['exotic_status'] ?? '').toString().trim();
        final originKey = origin.isEmpty ? 'Indigenous' : origin;
        origins[originKey] = (origins[originKey] ?? 0) + 1;

        final family = (h['family'] ?? '').toString().trim();
        if (family.isNotEmpty) {
          families[family] = (families[family] ?? 0) + 1;
        }
      }

      int approvedR = 0;
      for (final r in remedies) {
        final status = RecordValidationStatus.fromString(
          r['validation_status'] as String?,
        );
        if (status.isPublished) approvedR++;
      }

      final categories = <String, int>{};
      for (final a in ailmentsData) {
        final rawCat =
            (a['ailment_category'] ?? a['body_system'] ?? 'Other').toString();
        final label = _formatCategoryName(rawCat);
        categories[label] = (categories[label] ?? 0) + 1;
      }

      final sortedFamilies = Map.fromEntries(
        families.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
      );

      if (mounted) {
        setState(() {
          _analyticsTotalHerbs = herbs.length;
          _analyticsApprovedHerbs = approvedH;
          _analyticsTotalRemedies = remedies.length;
          _analyticsApprovedRemedies = approvedR;
          _analyticsTotalAilments = ailmentsData.length;
          _analyticsGrowthHabits = habits;
          _analyticsExoticStatuses = origins;
          _analyticsTopFamilies = Map.fromEntries(sortedFamilies.entries.take(5));
          _analyticsAilmentCategories = categories;
          _hasLoadedAnalytics = true;
          _isLoadingAnalytics = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminOverviewScreen] Error loading analytics: $e');
      if (mounted) {
        setState(() => _isLoadingAnalytics = false);
      }
    }
  }

  String _formatCategoryName(String raw) {
    if (raw.isEmpty) return 'Other';
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
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

                    // Realtime Live Online Users Stat Card
                    final onlineUsersCard = ValueListenableBuilder<int>(
                      valueListenable: UserPresenceService().onlineUserCount,
                      builder: (context, count, _) {
                        return _StatCard(
                          title: 'Online Now',
                          value: '$count',
                          icon: Icons.wifi_tethering_rounded,
                          color: const Color(0xFF0F766E),
                          onTap: () => widget.onNavigate?.call(6),
                          badge: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF22C55E),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    // On mobile: 2-column layout for uniform pairs
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
                          Row(
                            children: [
                              SizedBox(width: colWidth, height: cardHeight, child: onlineUsersCard),
                              const SizedBox(width: spacing),
                              SizedBox(width: colWidth, height: cardHeight, child: pendingReviewsCard),
                            ],
                          ),
                        ],
                      );
                    }

                    // On tablet & desktop viewports: dynamic wrapping
                    final int count = (availableWidth / 220).floor().clamp(1, 6);
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
                        SizedBox(width: cardWidth, height: cardHeight, child: usersCard),
                        SizedBox(width: cardWidth, height: cardHeight, child: onlineUsersCard),
                        SizedBox(width: cardWidth, height: cardHeight, child: pendingReviewsCard),
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

                const SizedBox(height: 32),

                // ─── Section: Collapsed Platform Analytics & Insights ────────
                _buildAnalyticsCollapsibleSection(rs),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCollapsibleSection(ResponsiveSize rs) {
    final herbApprovalRate = _analyticsTotalHerbs > 0
        ? (_analyticsApprovedHerbs / _analyticsTotalHerbs)
        : 1.0;
    final remedyApprovalRate = _analyticsTotalRemedies > 0
        ? (_analyticsApprovedRemedies / _analyticsTotalRemedies)
        : 1.0;
    final herbPercent = (herbApprovalRate * 100).round();
    final remedyPercent = (remedyApprovalRate * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Section: Platform Analytics & Insights Header (Outside Container) ─
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _isAnalyticsExpanded = !_isAnalyticsExpanded);
                if (_isAnalyticsExpanded && !_hasLoadedAnalytics) {
                  _loadAnalyticsData();
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Live Platform Analytics',
                    style: TextStyle(
                      fontSize: rs.titleFont * 1.1,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onNavigate != null) ...[
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded),
                    iconSize: 19,
                    color: const Color(0xFF1B5E20),
                    tooltip: 'Full Analytics View',
                    onPressed: () => widget.onNavigate?.call(8),
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFEAF5EB),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: Icon(
                    _isAnalyticsExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                  iconSize: 22,
                  color: const Color(0xFF1B5E20),
                  tooltip: _isAnalyticsExpanded ? 'Collapse' : 'Expand',
                  onPressed: () {
                    setState(() => _isAnalyticsExpanded = !_isAnalyticsExpanded);
                    if (_isAnalyticsExpanded && !_hasLoadedAnalytics) {
                      _loadAnalyticsData();
                    }
                  },
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEAF5EB),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ],
        ),

        // ─── Expandable Container Body ────────────────────────────────────────
        if (_isAnalyticsExpanded) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(18),
            child: _isLoadingAnalytics
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF2E7D32),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Compiling real-time platform analytics...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Verification Health Bars
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 600;
                          final herbHealth = _buildHealthGauge(
                            title: 'Herbs Publication Rate',
                            rateText: '$herbPercent%',
                            subtitle:
                                '$_analyticsApprovedHerbs of $_analyticsTotalHerbs published',
                            progress: herbApprovalRate,
                            accentColor: const Color(0xFF059669),
                            gradientColors: const [
                              Color(0xFF34D399),
                              Color(0xFF059669),
                            ],
                            icon: Icons.local_florist_rounded,
                          );
                          final remedyHealth = _buildHealthGauge(
                            title: 'Remedies Publication Rate',
                            rateText: '$remedyPercent%',
                            subtitle:
                                '$_analyticsApprovedRemedies of $_analyticsTotalRemedies published',
                            progress: remedyApprovalRate,
                            accentColor: const Color(0xFF2563EB),
                            gradientColors: const [
                              Color(0xFF60A5FA),
                              Color(0xFF2563EB),
                            ],
                            icon: Icons.healing_rounded,
                          );

                          if (isWide) {
                            return Row(
                              children: [
                                Expanded(child: herbHealth),
                                const SizedBox(width: 14),
                                Expanded(child: remedyHealth),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              herbHealth,
                              const SizedBox(height: 12),
                              remedyHealth,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // Row 2: Distribution Insights
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 600;
                          final habitsCard = _buildMiniBreakdownCard(
                            title: 'Herbs by Growth Habit',
                            icon: Icons.nature_rounded,
                            accentColor: const Color(0xFF059669),
                            palette: const [
                              Color(0xFF059669), // Emerald Forest
                              Color(0xFF0D9488), // Deep Teal
                              Color(0xFF10B981), // Mint
                              Color(0xFFD97706), // Amber Ochre
                              Color(0xFF65A30D), // Lime Olive
                            ],
                            data: _analyticsGrowthHabits,
                            total: _analyticsTotalHerbs,
                          );
                          final originCard = _buildMiniBreakdownCard(
                            title: 'Botanical Origin Status',
                            icon: Icons.public_rounded,
                            accentColor: const Color(0xFF2563EB),
                            palette: const [
                              Color(0xFF059669), // Indigenous Emerald
                              Color(0xFF2563EB), // Exotic Sapphire
                              Color(0xFFD97706), // Naturalized Amber
                              Color(0xFF64748B), // Slate Other
                            ],
                            data: _analyticsExoticStatuses,
                            total: _analyticsTotalHerbs,
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: habitsCard),
                                const SizedBox(width: 14),
                                Expanded(child: originCard),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              habitsCard,
                              const SizedBox(height: 12),
                              originCard,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // Row 3: Top Families & Ailment Categories
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 600;
                          final familiesCard = _buildMiniBreakdownCard(
                            title: 'Top Botanical Families',
                            icon: Icons.eco_rounded,
                            accentColor: const Color(0xFF7C3AED),
                            palette: const [
                              Color(0xFF7C3AED), // Amethyst Violet
                              Color(0xFF2563EB), // Sapphire
                              Color(0xFF0D9488), // Teal
                              Color(0xFFD97706), // Ochre Amber
                              Color(0xFFE11D48), // Rose Crimson
                            ],
                            data: _analyticsTopFamilies,
                            total: _analyticsTotalHerbs,
                          );
                          final ailmentsCard = _buildMiniBreakdownCard(
                            title: 'Ailments by Category',
                            icon: Icons.monitor_heart_outlined,
                            accentColor: const Color(0xFF0D9488),
                            palette: const [
                              Color(0xFF0D9488), // Clinical Teal
                              Color(0xFF2563EB), // Royal Blue
                              Color(0xFFE11D48), // Rose Coral
                              Color(0xFF7C3AED), // Purple
                              Color(0xFFEA580C), // Sunset Orange
                            ],
                            data: _analyticsAilmentCategories,
                            total: _analyticsTotalAilments,
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: familiesCard),
                                const SizedBox(width: 14),
                                Expanded(child: ailmentsCard),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              familiesCard,
                              const SizedBox(height: 12),
                              ailmentsCard,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildHealthGauge({
    required String title,
    required String rateText,
    required String subtitle,
    required double progress,
    required Color accentColor,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rateText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(7),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBreakdownCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Color> palette,
    required Map<String, int> data,
    required int total,
  }) {
    final entries = data.entries.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text(
              'No distribution data available',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            )
          else
            ...entries.asMap().entries.map((mapEntry) {
              final index = mapEntry.key;
              final entry = mapEntry.value;
              final itemColor = palette[index % palette.length];
              final pct = total > 0 ? (entry.value / total) : 0.0;
              final pctText = '${(pct * 100).round()}%';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: itemColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: itemColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${entry.value} ($pctText)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: itemColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: pct.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                itemColor.withValues(alpha: 0.75),
                                itemColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
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
  final Widget? badge;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.badge,
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
                  if (badge != null) badge!,
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
