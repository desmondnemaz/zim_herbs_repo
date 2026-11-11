import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';

/// Admin Analytics screen displaying live visual charts, distributions,
/// and repository insights across herbs, ailments, remedies, and users.
class AdminAnalyticsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const AdminAnalyticsScreen({super.key, this.onBack});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = true;

  int _totalHerbs = 0;
  int _approvedHerbs = 0;
  int _totalRemedies = 0;
  int _approvedRemedies = 0;
  int _totalAilments = 0;
  int _totalUsers = 0;

  Map<String, int> _growthHabits = {};
  Map<String, int> _exoticStatuses = {};
  Map<String, int> _topFamilies = {};
  Map<String, int> _ailmentCategories = {};
  Map<String, int> _userRoles = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

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
        _client
            .from('user_profiles')
            .select()
            .then((v) => List<Map<String, dynamic>>.from(v))
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);

      final herbs = results[0];
      final remedies = results[1];
      final users = results[2];

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

      final roles = <String, int>{};
      for (final u in users) {
        final rawRole = (u['role'] ?? 'user').toString().trim();
        final label = rawRole.isEmpty
            ? 'User'
            : '${rawRole[0].toUpperCase()}${rawRole.substring(1)}';
        roles[label] = (roles[label] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          _totalHerbs = herbs.length;
          _approvedHerbs = approvedH;
          _totalRemedies = remedies.length;
          _approvedRemedies = approvedR;
          _totalAilments = ailmentsData.length;
          _totalUsers = users.length;
          _growthHabits = _sortByCountDesc(habits);
          _exoticStatuses = _sortByCountDesc(origins);
          _topFamilies = _sortByCountDesc(families, limit: 6);
          _ailmentCategories = _sortByCountDesc(categories);
          _userRoles = _sortByCountDesc(roles);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  static Map<String, int> _sortByCountDesc(
    Map<String, int> map, {
    int? limit,
  }) {
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sliced = limit != null ? entries.take(limit) : entries;
    return {for (final e in sliced) e.key: e.value};
  }

  static String _formatCategoryName(String raw) {
    final cleaned = raw.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return 'General';
    return cleaned
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);

    final herbApprovalRate =
        _totalHerbs == 0 ? 0.0 : _approvedHerbs / _totalHerbs;
    final remedyApprovalRate =
        _totalRemedies == 0 ? 0.0 : _approvedRemedies / _totalRemedies;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F2),
      appBar: isDesktop
          ? null
          : AppPageAppBar(
              title: 'Analytics',
              onBack: widget.onBack,
            ),
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Live Platform Analytics',
              subtitle:
                  'Visual breakdowns of botanical records, ailment categories, and community activity',
              icon: Icons.analytics_rounded,
              onBack: widget.onBack,
              trailing: IconButton(
                tooltip: 'Refresh Analytics',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _isLoading ? null : _loadAnalytics,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadAnalytics,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(rs.defaultPadding),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1180),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── 1. Verification & Publication Health ──
                                _buildVerificationHealthSection(
                                  isMobile: isMobile,
                                  herbRate: herbApprovalRate,
                                  remedyRate: remedyApprovalRate,
                                ),
                                const SizedBox(height: 20),

                                // ── 2. Distribution Charts Grid ──
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth >= 780;

                                    final habitsChart = _DistributionChartCard(
                                      title: 'Herbs by Growth Habit',
                                      subtitle:
                                          'Plant form distribution ($_totalHerbs total)',
                                      icon: Icons.nature_rounded,
                                      accentColor: const Color(0xFF059669),
                                      palette: const [
                                        Color(0xFF059669), // Emerald
                                        Color(0xFF0D9488), // Deep Teal
                                        Color(0xFF10B981), // Mint
                                        Color(0xFFD97706), // Amber Ochre
                                        Color(0xFF65A30D), // Lime Olive
                                      ],
                                      data: _growthHabits,
                                      total: _totalHerbs,
                                    );

                                    final originsChart = _DistributionChartCard(
                                      title: 'Botanical Origin Status',
                                      subtitle:
                                          'Indigenous vs. Naturalized & Exotic flora',
                                      icon: Icons.public_rounded,
                                      accentColor: const Color(0xFF2563EB),
                                      palette: const [
                                        Color(0xFF059669), // Indigenous Emerald
                                        Color(0xFF2563EB), // Exotic Sapphire
                                        Color(0xFFD97706), // Naturalized Amber
                                        Color(0xFF64748B), // Slate Other
                                      ],
                                      data: _exoticStatuses,
                                      total: _totalHerbs,
                                    );

                                    final ailmentsChart =
                                        _DistributionChartCard(
                                          title: 'Ailments by Category',
                                          subtitle:
                                              'Medical category breakdown ($_totalAilments total)',
                                          icon: Icons.monitor_heart_outlined,
                                          accentColor: const Color(0xFF0D9488),
                                          palette: const [
                                            Color(0xFF0D9488), // Clinical Teal
                                            Color(0xFF2563EB), // Royal Blue
                                            Color(0xFFE11D48), // Rose Coral
                                            Color(0xFF7C3AED), // Amethyst
                                            Color(0xFFEA580C), // Sunset Orange
                                          ],
                                          data: _ailmentCategories,
                                          total: _totalAilments,
                                        );

                                    final familiesChart =
                                        _DistributionChartCard(
                                          title: 'Top Botanical Plant Families',
                                          subtitle:
                                              'Most documented taxonomic families',
                                          icon: Icons.local_florist_rounded,
                                          accentColor: const Color(0xFF7C3AED),
                                          palette: const [
                                            Color(0xFF7C3AED), // Amethyst Violet
                                            Color(0xFF2563EB), // Sapphire
                                            Color(0xFF0D9488), // Teal
                                            Color(0xFFD97706), // Ochre Amber
                                            Color(0xFFE11D48), // Rose Crimson
                                          ],
                                          data: _topFamilies,
                                          total: _totalHerbs,
                                        );

                                    final rolesChart = _DistributionChartCard(
                                      title: 'Community User Roles',
                                      subtitle:
                                          'Registered accounts by role ($_totalUsers total)',
                                      icon: Icons.people_outline_rounded,
                                      accentColor: const Color(0xFF2563EB),
                                      palette: const [
                                        Color(0xFF2563EB), // Royal Blue
                                        Color(0xFF059669), // Emerald
                                        Color(0xFFD97706), // Amber
                                        Color(0xFF7C3AED), // Violet
                                        Color(0xFF64748B), // Slate
                                      ],
                                      data: _userRoles,
                                      total: _totalUsers,
                                    );

                                    if (isWide) {
                                      return Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: habitsChart),
                                              const SizedBox(width: 16),
                                              Expanded(child: originsChart),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: ailmentsChart),
                                              const SizedBox(width: 16),
                                              Expanded(child: familiesChart),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          rolesChart,
                                        ],
                                      );
                                    }

                                    return Column(
                                      children: [
                                        habitsChart,
                                        const SizedBox(height: 14),
                                        originsChart,
                                        const SizedBox(height: 14),
                                        ailmentsChart,
                                        const SizedBox(height: 14),
                                        familiesChart,
                                        const SizedBox(height: 14),
                                        rolesChart,
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationHealthSection({
    required bool isMobile,
    required double herbRate,
    required double remedyRate,
  }) {
    final herbPercent = (herbRate * 100).round();
    final remedyPercent = (remedyRate * 100).round();

    final herbCard = _ApprovalGaugeCard(
      title: 'Herbs Verification Rate',
      approvedCount: _approvedHerbs,
      pendingCount: (_totalHerbs - _approvedHerbs).clamp(0, _totalHerbs),
      percent: herbPercent,
      progress: herbRate,
      color: const Color(0xFF22633C),
      icon: Icons.local_florist_rounded,
    );

    final remedyCard = _ApprovalGaugeCard(
      title: 'Remedies Approval Rate',
      approvedCount: _approvedRemedies,
      pendingCount: (_totalRemedies - _approvedRemedies).clamp(
        0,
        _totalRemedies,
      ),
      percent: remedyPercent,
      progress: remedyRate,
      color: const Color(0xFF295CA2),
      icon: Icons.healing_outlined,
    );

    if (isMobile) {
      return Column(
        children: [
          herbCard,
          const SizedBox(height: 12),
          remedyCard,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: herbCard),
        const SizedBox(width: 16),
        Expanded(child: remedyCard),
      ],
    );
  }
}

class _ApprovalGaugeCard extends StatelessWidget {
  final String title;
  final int approvedCount;
  final int pendingCount;
  final int percent;
  final double progress;
  final Color color;
  final IconData icon;

  const _ApprovalGaugeCard({
    required this.title,
    required this.approvedCount,
    required this.pendingCount,
    required this.percent,
    required this.progress,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.75),
                      color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$approvedCount Published',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                '$pendingCount Pending Review',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistributionChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<Color>? palette;
  final Map<String, int> data;
  final int total;

  static const List<Color> _defaultPalette = [
    Color(0xFF059669), // Emerald
    Color(0xFF2563EB), // Sapphire Blue
    Color(0xFF0D9488), // Deep Teal
    Color(0xFFD97706), // Amber Ochre
    Color(0xFF7C3AED), // Amethyst Violet
    Color(0xFFE11D48), // Rose Crimson
    Color(0xFFEA580C), // Sunset Orange
  ];

  const _DistributionChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.palette,
    required this.data,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final activePalette = palette ?? _defaultPalette;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No data available yet.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ...entries.asMap().entries.map((mapEntry) {
              final index = mapEntry.key;
              final e = mapEntry.value;
              final itemColor = activePalette[index % activePalette.length];
              final ratio = total <= 0 ? 0.0 : (e.value / total).clamp(0.0, 1.0);
              final pct = (ratio * 100).round();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: itemColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              e.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: itemColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${e.value} ($pct%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: itemColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: ratio,
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

