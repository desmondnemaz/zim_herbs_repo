import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/models/herb_model.dart';
import 'package:zim_herbs_repo/features/repository/remedies/data/models/remedy_model.dart';
import '../../data/datasources/moderation_remote_datasource.dart';
import '../../data/models/herbalist_moderation_model.dart';

/// Comprehensive Moderation Hub for verifying Herbs, Remedies, and Herbalist Practitioners.
class ModerationHubScreen extends StatefulWidget {
  final UserModel moderator;

  const ModerationHubScreen({super.key, required this.moderator});

  @override
  State<ModerationHubScreen> createState() => _ModerationHubScreenState();
}

class _ModerationHubScreenState extends State<ModerationHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ModerationRemoteDataSource _datasource;

  // Herbs State
  List<HerbModel> _herbs = [];
  bool _loadingHerbs = true;
  Failure? _herbsError;
  String _herbSearchQuery = '';
  String _herbFilter = 'all'; // 'all', 'pending', 'verified'

  // Remedies State
  List<RemedyModel> _remedies = [];
  bool _loadingRemedies = true;
  Failure? _remediesError;
  String _remedySearchQuery = '';
  String _remedyFilter = 'all'; // 'all', 'pending', 'verified'

  // Herbalists State
  List<HerbalistModerationModel> _herbalists = [];
  bool _loadingHerbalists = true;
  Failure? _herbalistsError;
  String _herbalistSearchQuery = '';
  String _herbalistFilter = 'all'; // 'all', 'pending', 'verified', 'rejected'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _datasource = ModerationRemoteDataSource(Supabase.instance.client);

    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAll() {
    _loadHerbs();
    _loadRemedies();
    _loadHerbalists();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Herbs Operations
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _loadHerbs() async {
    setState(() {
      _loadingHerbs = true;
      _herbsError = null;
    });
    try {
      final results = await _datasource.getHerbsForModeration();
      if (mounted) {
        setState(() {
          _herbs = results;
          _loadingHerbs = false;
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _herbsError = ErrorHandler.handle(e, st);
          _loadingHerbs = false;
        });
      }
    }
  }

  Future<void> _toggleHerbApproval(HerbModel herb) async {
    final newStatus = !herb.isApproved;
    try {
      await _datasource.updateHerbApproval(herb.id, newStatus);
      if (mounted) {
        setState(() {
          final index = _herbs.indexWhere((h) => h.id == herb.id);
          if (index != -1) {
            _herbs[index] = HerbModel(
              id: herb.id,
              nameEn: herb.nameEn,
              nameSn: herb.nameSn,
              nameNd: herb.nameNd,
              description: herb.description,
              isApproved: newStatus,
              images: herb.images,
              remedies: herb.remedies,
              createdAt: herb.createdAt,
              updatedAt: DateTime.now(),
            );
          }
        });
        showAppErrorSnackBar(
          context,
          title: newStatus ? 'Herb Verified' : 'Verification Revoked',
          message:
              '${herb.nameEn} has been ${newStatus ? 'verified and published' : 'marked as unverified'}.',
          type: FailureType.validation,
        );
      }
    } catch (e, st) {
      if (mounted) {
        showAppErrorSnackBar(
          context,
          failure: ErrorHandler.handle(e, st),
        );
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Remedies Operations
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _loadRemedies() async {
    setState(() {
      _loadingRemedies = true;
      _remediesError = null;
    });
    try {
      final results = await _datasource.getRemediesForModeration();
      if (mounted) {
        setState(() {
          _remedies = results;
          _loadingRemedies = false;
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _remediesError = ErrorHandler.handle(e, st);
          _loadingRemedies = false;
        });
      }
    }
  }

  Future<void> _approveRemedy(RemedyModel remedy) async {
    try {
      await _datasource.updateRemedyApproval(
        remedy.id,
        true,
        moderatorId: widget.moderator.id,
      );
      if (mounted) {
        _loadRemedies();
        showAppErrorSnackBar(
          context,
          title: 'Remedy Verified',
          message: '${remedy.name} has been approved for community display.',
          type: FailureType.validation,
        );
      }
    } catch (e, st) {
      if (mounted) {
        showAppErrorSnackBar(context, failure: ErrorHandler.handle(e, st));
      }
    }
  }

  Future<void> _rejectRemedyDialog(RemedyModel remedy) async {
    final commentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Remedy Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify reasons or feedback for "${remedy.name}":',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Inaccurate dosage, missing precautions...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject Remedy'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _datasource.updateRemedyApproval(
          remedy.id,
          false,
          moderatorId: widget.moderator.id,
          comments: commentController.text.trim(),
        );
        if (mounted) {
          _loadRemedies();
          showAppErrorSnackBar(
            context,
            title: 'Remedy Rejected',
            message: '${remedy.name} submission has been rejected.',
            type: FailureType.validation,
          );
        }
      } catch (e, st) {
        if (mounted) {
          showAppErrorSnackBar(context, failure: ErrorHandler.handle(e, st));
        }
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. Herbalists / Practitioner Operations
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _loadHerbalists() async {
    setState(() {
      _loadingHerbalists = true;
      _herbalistsError = null;
    });
    try {
      final results = await _datasource.getHerbalistsForModeration();
      if (mounted) {
        setState(() {
          _herbalists = results;
          _loadingHerbalists = false;
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _herbalistsError = ErrorHandler.handle(e, st);
          _loadingHerbalists = false;
        });
      }
    }
  }

  Future<void> _setHerbalistStatus(
    HerbalistModerationModel herbalist,
    String status,
  ) async {
    try {
      await _datasource.updateHerbalistStatus(herbalist.id, status);
      if (mounted) {
        _loadHerbalists();
        final isVerified = status == 'verified';
        showAppErrorSnackBar(
          context,
          title: isVerified ? 'Practitioner Verified' : 'Application Rejected',
          message:
              '${herbalist.fullName} has been ${isVerified ? 'verified as licensed herbalist' : 'rejected'}.',
          type: FailureType.validation,
        );
      }
    } catch (e, st) {
      if (mounted) {
        showAppErrorSnackBar(context, failure: ErrorHandler.handle(e, st));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rs = ResponsiveSize(context);

    // Pending counts for badges
    final pendingHerbsCount = _herbs.where((h) => !h.isApproved).length;
    final pendingRemediesCount = _remedies.where((r) => !r.isApproved).length;
    final pendingHerbalistsCount =
        _herbalists.where((h) => h.isPending).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.verified_user_rounded,
                color: theme.colorScheme.secondary, size: 24),
            const SizedBox(width: 10),
            const Text(
              'Moderation Hub',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.secondary,
          unselectedLabelColor: Colors.white70,
          indicatorColor: theme.colorScheme.secondary,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_florist_rounded, size: 16),
                  const SizedBox(width: 6),
                  const Text('Herbs'),
                  if (pendingHerbsCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildCountBadge(pendingHerbsCount, Colors.amber.shade700),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.healing_rounded, size: 16),
                  const SizedBox(width: 6),
                  const Text('Remedies'),
                  if (pendingRemediesCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildCountBadge(
                        pendingRemediesCount, Colors.amber.shade700),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.medical_services_rounded, size: 16),
                  const SizedBox(width: 6),
                  const Text('Practitioners'),
                  if (pendingHerbalistsCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildCountBadge(
                        pendingHerbalistsCount, Colors.amber.shade700),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHerbsTab(theme, rs),
          _buildRemediesTab(theme, rs),
          _buildPractitionersTab(theme, rs),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab 1: Herbs Moderation View
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHerbsTab(ThemeData theme, ResponsiveSize rs) {
    if (_loadingHerbs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_herbsError != null) {
      return AppErrorView(
        failure: _herbsError,
        onRetry: _loadHerbs,
      );
    }

    final filtered = _herbs.where((h) {
      final q = _herbSearchQuery.toLowerCase();
      final matchesSearch = h.nameEn.toLowerCase().contains(q) ||
          (h.nameSn?.toLowerCase().contains(q) ?? false) ||
          (h.nameNd?.toLowerCase().contains(q) ?? false);

      final matchesFilter = switch (_herbFilter) {
        'pending' => !h.isApproved,
        'verified' => h.isApproved,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadHerbs,
      child: Column(
        children: [
          // Filter & Search Header
          Padding(
            padding: EdgeInsets.all(rs.defaultPadding),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search herbs by English, Shona or Ndebele name...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onChanged: (val) => setState(() => _herbSearchQuery = val),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _filterChip('All (${_herbs.length})', 'all', _herbFilter,
                        (v) => setState(() => _herbFilter = v)),
                    const SizedBox(width: 8),
                    _filterChip(
                      'Pending (${_herbs.where((h) => !h.isApproved).length})',
                      'pending',
                      _herbFilter,
                      (v) => setState(() => _herbFilter = v),
                      activeColor: Colors.amber.shade800,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      'Verified (${_herbs.where((h) => h.isApproved).length})',
                      'verified',
                      _herbFilter,
                      (v) => setState(() => _herbFilter = v),
                      activeColor: Colors.green.shade700,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No herbs found matching criteria.'),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: rs.defaultPadding),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final herb = filtered[index];
                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: herb.isApproved
                                ? Colors.green.shade300
                                : Colors.amber.shade400,
                            width: 1.2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Herb Thumbnail
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  image: herb.primaryImageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                              herb.primaryImageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: herb.primaryImageUrl == null
                                    ? Icon(Icons.local_florist,
                                        color: Colors.green.shade700)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            herb.nameEn,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        _statusBadge(
                                          herb.isApproved
                                              ? 'Verified'
                                              : 'Pending Review',
                                          herb.isApproved
                                              ? Colors.green
                                              : Colors.amber.shade800,
                                        ),
                                      ],
                                    ),
                                    if (herb.nameSn != null ||
                                        herb.nameNd != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        [
                                          if (herb.nameSn != null)
                                            'SN: ${herb.nameSn}',
                                          if (herb.nameNd != null)
                                            'ND: ${herb.nameNd}',
                                        ].join(' | '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                    if (herb.description != null &&
                                        herb.description!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        herb.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Quick Action
                              IconButton.filledTonal(
                                tooltip: herb.isApproved
                                    ? 'Revoke Verification'
                                    : 'Verify Herb',
                                icon: Icon(
                                  herb.isApproved
                                      ? Icons.close_rounded
                                      : Icons.check_circle_outline_rounded,
                                  color: herb.isApproved
                                      ? Colors.orange.shade800
                                      : Colors.green.shade700,
                                ),
                                onPressed: () => _toggleHerbApproval(herb),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab 2: Remedies Moderation View
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRemediesTab(ThemeData theme, ResponsiveSize rs) {
    if (_loadingRemedies) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_remediesError != null) {
      return AppErrorView(
        failure: _remediesError,
        onRetry: _loadRemedies,
      );
    }

    final filtered = _remedies.where((r) {
      final q = _remedySearchQuery.toLowerCase();
      final matchesSearch = r.name.toLowerCase().contains(q) ||
          (r.condition?.name.toLowerCase().contains(q) ?? false);

      final matchesFilter = switch (_remedyFilter) {
        'pending' => !r.isApproved,
        'verified' => r.isApproved,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadRemedies,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(rs.defaultPadding),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search remedies by name or condition...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onChanged: (val) => setState(() => _remedySearchQuery = val),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _filterChip('All (${_remedies.length})', 'all',
                        _remedyFilter, (v) => setState(() => _remedyFilter = v)),
                    const SizedBox(width: 8),
                    _filterChip(
                      'Pending (${_remedies.where((r) => !r.isApproved).length})',
                      'pending',
                      _remedyFilter,
                      (v) => setState(() => _remedyFilter = v),
                      activeColor: Colors.amber.shade800,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      'Verified (${_remedies.where((r) => r.isApproved).length})',
                      'verified',
                      _remedyFilter,
                      (v) => setState(() => _remedyFilter = v),
                      activeColor: Colors.green.shade700,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No remedies found matching criteria.'),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: rs.defaultPadding),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final remedy = filtered[index];
                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: remedy.isApproved
                                ? Colors.green.shade300
                                : Colors.amber.shade400,
                            width: 1.2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          remedy.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (remedy.condition != null)
                                          Text(
                                            'For: ${remedy.condition!.name}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  _statusBadge(
                                    remedy.isApproved
                                        ? 'Verified'
                                        : 'Pending Review',
                                    remedy.isApproved
                                        ? Colors.green
                                        : Colors.amber.shade800,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (remedy.preparation.isNotEmpty) ...[
                                Text(
                                  'Preparation: ${remedy.preparation}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                              if (remedy.dosageAdults != null) ...[
                                Text(
                                  'Dosage (Adults): ${remedy.dosageAdults}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                              if (remedy.moderationComments != null &&
                                  remedy.moderationComments!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.feedback_outlined,
                                          size: 15, color: Colors.red.shade700),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Moderator Note: ${remedy.moderationComments}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.red.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              // Action Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _rejectRemedyDialog(remedy),
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('Reject / Comments'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red.shade700,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: remedy.isApproved
                                        ? null
                                        : () => _approveRemedy(remedy),
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Approve Remedy'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab 3: Practitioners / Herbalist Profiles View
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPractitionersTab(ThemeData theme, ResponsiveSize rs) {
    if (_loadingHerbalists) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_herbalistsError != null) {
      return AppErrorView(
        failure: _herbalistsError,
        onRetry: _loadHerbalists,
      );
    }

    final filtered = _herbalists.where((h) {
      final q = _herbalistSearchQuery.toLowerCase();
      final matchesSearch = h.fullName.toLowerCase().contains(q) ||
          h.email.toLowerCase().contains(q) ||
          h.specialisation.toLowerCase().contains(q) ||
          (h.location?.toLowerCase().contains(q) ?? false);

      final matchesFilter = switch (_herbalistFilter) {
        'pending' => h.isPending,
        'verified' => h.isVerified,
        'rejected' => h.isRejected,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadHerbalists,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(rs.defaultPadding),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search practitioners by name, email, specialty, location...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onChanged: (val) =>
                      setState(() => _herbalistSearchQuery = val),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _filterChip('All (${_herbalists.length})', 'all',
                        _herbalistFilter, (v) => setState(() => _herbalistFilter = v)),
                    _filterChip(
                      'Pending (${_herbalists.where((h) => h.isPending).length})',
                      'pending',
                      _herbalistFilter,
                      (v) => setState(() => _herbalistFilter = v),
                      activeColor: Colors.amber.shade800,
                    ),
                    _filterChip(
                      'Verified (${_herbalists.where((h) => h.isVerified).length})',
                      'verified',
                      _herbalistFilter,
                      (v) => setState(() => _herbalistFilter = v),
                      activeColor: Colors.green.shade700,
                    ),
                    _filterChip(
                      'Rejected (${_herbalists.where((h) => h.isRejected).length})',
                      'rejected',
                      _herbalistFilter,
                      (v) => setState(() => _herbalistFilter = v),
                      activeColor: Colors.red.shade700,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No practitioner profiles matching criteria.'),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: rs.defaultPadding),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final herbalist = filtered[index];
                      final statusColor = herbalist.isVerified
                          ? Colors.green
                          : (herbalist.isRejected
                              ? Colors.red
                              : Colors.amber.shade800);

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: statusColor.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.indigo.shade100,
                                    backgroundImage: herbalist.avatarUrl != null
                                        ? NetworkImage(herbalist.avatarUrl!)
                                        : null,
                                    child: herbalist.avatarUrl == null
                                        ? Text(
                                            herbalist.fullName.isNotEmpty
                                                ? herbalist.fullName[0].toUpperCase()
                                                : 'P',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.indigo.shade800,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          herbalist.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          herbalist.email,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        if (herbalist.phoneNumber != null)
                                          Text(
                                            'Phone: ${herbalist.phoneNumber}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  _statusBadge(
                                    herbalist.verificationStatus.toUpperCase(),
                                    statusColor,
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _metaInfo(
                                      Icons.school_outlined,
                                      'Specialisation',
                                      herbalist.specialisation,
                                    ),
                                  ),
                                  Expanded(
                                    child: _metaInfo(
                                      Icons.history_toggle_off_rounded,
                                      'Experience',
                                      '${herbalist.yearsOfExperience} years',
                                    ),
                                  ),
                                  if (herbalist.location != null)
                                    Expanded(
                                      child: _metaInfo(
                                        Icons.location_on_outlined,
                                        'Location',
                                        herbalist.location!,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!herbalist.isRejected)
                                    OutlinedButton.icon(
                                      onPressed: () => _setHerbalistStatus(
                                          herbalist, 'rejected'),
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text('Reject Practitioner'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red.shade700,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  if (!herbalist.isVerified)
                                    ElevatedButton.icon(
                                      onPressed: () => _setHerbalistStatus(
                                          herbalist, 'verified'),
                                      icon: const Icon(Icons.verified, size: 16),
                                      label: const Text('Verify Practitioner'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        foregroundColor: Colors.white,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _metaInfo(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _filterChip(
    String label,
    String value,
    String current,
    ValueChanged<String> onSelected, {
    Color? activeColor,
  }) {
    final isSelected = value == current;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: (activeColor ?? Theme.of(context).colorScheme.primary)
          .withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? (activeColor ?? Theme.of(context).colorScheme.primary)
            : Colors.grey.shade700,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
