import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/models/herb_model.dart';
import 'package:zim_herbs_repo/features/repository/remedies/data/models/remedy_model.dart';
import 'package:zim_herbs_repo/core/components/record_audit_timeline.dart';
import 'package:zim_herbs_repo/core/components/rejection_reason_dialog.dart';
import 'package:zim_herbs_repo/core/components/validation_status_chip.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/features/admin/herb_management/presentation/add_edit_herb_page.dart';
import 'package:zim_herbs_repo/features/admin/remedy_management/presentation/add_edit_remedy_page.dart';
import 'package:zim_herbs_repo/core/components/app_badged_tab_bar.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/components/app_filter_bar.dart';
import 'package:zim_herbs_repo/core/components/app_search_bar.dart';
import 'package:zim_herbs_repo/core/components/herb_review_card.dart';
import 'package:zim_herbs_repo/core/components/remedy_review_card.dart';
import 'package:zim_herbs_repo/core/components/practitioner_review_card.dart';
import 'package:zim_herbs_repo/core/components/supplier_review_card.dart';
import '../../data/datasources/moderation_remote_datasource.dart';
import '../../data/models/herbalist_moderation_model.dart';
import '../../data/models/supplier_moderation_model.dart';

/// Comprehensive Moderation Hub for verifying Herbs, Remedies, Herbalists, and Suppliers.
class ModerationHubScreen extends StatefulWidget {
  final UserModel moderator;
  final VoidCallback? onBack;

  const ModerationHubScreen({
    super.key,
    required this.moderator,
    this.onBack,
  });

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
  String _herbFilter = 'pending'; // Default to 'pending' unverified herbs for moderators!

  // Remedies State
  List<RemedyModel> _remedies = [];
  bool _loadingRemedies = true;
  Failure? _remediesError;
  String _remedySearchQuery = '';
  String _remedyFilter = 'pending'; // Default to 'pending' unverified remedies for moderators!

  // Herbalists State
  List<HerbalistModerationModel> _herbalists = [];
  bool _loadingHerbalists = true;
  Failure? _herbalistsError;
  String _herbalistSearchQuery = '';
  String _herbalistFilter = 'all'; // 'all', 'pending', 'verified', 'rejected'

  // Suppliers State
  List<SupplierModerationModel> _suppliers = [];
  bool _loadingSuppliers = true;
  Failure? _suppliersError;
  String _supplierSearchQuery = '';
  String _supplierFilter = 'all'; // 'all', 'pending', 'verified', 'rejected'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    _loadSuppliers();
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

  Future<void> _updateHerbStage(
    HerbModel herb,
    RecordValidationStatus stage, {
    String? reason,
  }) async {
    try {
      await _datasource.updateHerbValidationStatus(
        herb.id,
        stage,
        moderatorId: widget.moderator.id,
        reason: reason,
      );
      if (mounted) {
        _loadHerbs();
        showAppErrorSnackBar(
          context,
          title: 'Status Updated: ${stage.label}',
          message: '${herb.nameEn} status is now marked as ${stage.label}.',
          type: FailureType.validation,
        );
      }
    } catch (e, st) {
      if (mounted) {
        showAppErrorSnackBar(context, failure: ErrorHandler.handle(e, st));
      }
    }
  }

  Future<void> _openEditHerb(HerbModel herb) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditHerbPage(herb: herb),
      ),
    );

    if (result == true || result != null) {
      _loadHerbs();
    }
  }

  Future<void> _deleteHerb(HerbModel herb) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Herb Submission'),
        content: Text(
          'Are you sure you want to permanently delete "${herb.nameEn}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _datasource.deleteHerb(herb.id);
        setState(() {
          _herbs.removeWhere((h) => h.id == herb.id);
        });
        if (!mounted) return;
        showAppErrorSnackBar(
          context,
          title: 'Herb Deleted',
          message: '${herb.nameEn} has been deleted.',
          type: FailureType.validation,
        );
      } catch (e, st) {
        if (mounted) {
          showAppErrorSnackBar(
            context,
            failure: ErrorHandler.handle(e, st),
          );
        }
      }
    }
  }

  void _showHerbDetailsSheet(HerbModel herb) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          image: herb.primaryImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(herb.primaryImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: herb.primaryImageUrl == null
                            ? Icon(Icons.local_florist,
                                size: 36, color: Colors.green.shade700)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              herb.nameEn,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ValidationStatusChip(
                              status: herb.validationStatus,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (herb.nameSn != null || herb.nameNd != null) ...[
                    const Text('Indigenous Dialect Names:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (herb.nameSn != null)
                          Chip(
                            label: Text('Shona: ${herb.nameSn}'),
                            backgroundColor: Colors.green.shade50,
                          ),
                        if (herb.nameNd != null)
                          Chip(
                            label: Text('Ndebele: ${herb.nameNd}'),
                            backgroundColor: Colors.blue.shade50,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text('Description:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    (herb.description != null && herb.description!.isNotEmpty)
                        ? herb.description!
                        : 'No description provided.',
                    style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (herb.remedies.isNotEmpty) ...[
                    Text('Associated Remedies (${herb.remedies.length}):',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    ...herb.remedies.map(
                      (r) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.healing,
                            size: 18, color: Colors.teal),
                        title: Text(r.name),
                        subtitle: r.condition != null
                            ? Text('Condition: ${r.condition!.name}')
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (herb.images.isNotEmpty) ...[
                    Text('Images (${herb.images.length}):',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: herb.images.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (ctx2, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            herb.images[i].imageUrl,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Divider(),
                  const SizedBox(height: 12),
                  RecordAuditTimeline(
                    history: herb.auditHistory,
                    currentStatus: herb.validationStatus,
                    title: 'Verification & Audit History',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Update Herb'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openEditHerb(herb);
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteHerb(herb);
                        },
                      ),
                      if (herb.validationStatus == RecordValidationStatus.submitted) ...[
                        FilledButton.icon(
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text('Start Review'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateHerbStage(herb, RecordValidationStatus.underReview);
                          },
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text('Validate Herb'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateHerbStage(herb, RecordValidationStatus.validated);
                          },
                        ),
                      ] else if (herb.validationStatus == RecordValidationStatus.underReview) ...[
                        FilledButton.icon(
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text('Validate Herb'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateHerbStage(herb, RecordValidationStatus.validated);
                          },
                        ),
                      ] else if (herb.validationStatus == RecordValidationStatus.validated) ...[
                        FilledButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Publish to Public'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateHerbStage(herb, RecordValidationStatus.published);
                          },
                        ),
                      ] else if (herb.validationStatus == RecordValidationStatus.published) ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.visibility_off_outlined),
                          label: const Text('Unpublish'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade800),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateHerbStage(herb, RecordValidationStatus.validated);
                          },
                        ),
                      ] else if (herb.validationStatus == RecordValidationStatus.rejected) ...[
                        FilledButton.icon(
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('Re-open for Review'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateHerbStage(herb, RecordValidationStatus.underReview);
                          },
                        ),
                      ],
                      if (herb.validationStatus != RecordValidationStatus.rejected)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Reject Submission'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final reason = await RejectionReasonDialog.show(
                              context,
                              recordName: herb.nameEn,
                              recordType: 'Herb',
                            );
                            if (reason != null && reason.trim().isNotEmpty) {
                              _updateHerbStage(herb, RecordValidationStatus.rejected, reason: reason.trim());
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
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


  Future<void> _rejectRemedyDialog(RemedyModel remedy) async {
    final reason = await RejectionReasonDialog.show(
      context,
      recordName: remedy.name,
      recordType: 'Remedy',
    );

    if (reason != null && reason.trim().isNotEmpty) {
      _updateRemedyStage(
        remedy,
        RecordValidationStatus.rejected,
        reason: reason.trim(),
      );
    }
  }

  Future<void> _openEditRemedy(RemedyModel remedy) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditRemedyPage(remedy: remedy.toEntity()),
      ),
    );

    if (result == true || result != null) {
      _loadRemedies();
    }
  }

  Future<void> _deleteRemedy(RemedyModel remedy) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Remedy Submission'),
        content: Text(
          'Are you sure you want to permanently delete "${remedy.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _datasource.deleteRemedy(remedy.id);
        setState(() {
          _remedies.removeWhere((r) => r.id == remedy.id);
        });
        if (!mounted) return;
        showAppErrorSnackBar(
          context,
          title: 'Remedy Deleted',
          message: '${remedy.name} has been deleted.',
          type: FailureType.validation,
        );
      } catch (e, st) {
        if (mounted) {
          showAppErrorSnackBar(
            context,
            failure: ErrorHandler.handle(e, st),
          );
        }
      }
    }
  }

  Future<void> _updateRemedyStage(
    RemedyModel remedy,
    RecordValidationStatus stage, {
    String? reason,
  }) async {
    try {
      await _datasource.updateRemedyValidationStatus(
        remedy.id,
        stage,
        moderatorId: widget.moderator.id,
        reason: reason,
      );
      if (mounted) {
        _loadRemedies();
        showAppErrorSnackBar(
          context,
          title: 'Status Updated: ${stage.label}',
          message: '${remedy.name} status is now marked as ${stage.label}.',
          type: FailureType.validation,
        );
      }
    } catch (e, st) {
      if (mounted) {
        showAppErrorSnackBar(context, failure: ErrorHandler.handle(e, st));
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
    final isVerified = status.toLowerCase() == 'verified';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isVerified ? Colors.green : Colors.red)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVerified ? Icons.verified_user_rounded : Icons.cancel_outlined,
                color: isVerified ? Colors.green.shade700 : Colors.red.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isVerified
                    ? 'Grant Practitioner Role'
                    : 'Reject Practitioner Application',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isVerified
              ? 'Are you sure you want to verify "${herbalist.fullName}" as an accredited Traditional Practitioner?\n\n'
                  '• "user_profiles.is_practitioner" will be set to TRUE.\n'
                  '• "herbalist_profiles.verification_status" will be persisted as VERIFIED.\n'
                  '• Telemedicine consultation booking will be enabled for this profile.\n\n'
                  'Confirm updating and persisting to the database?'
              : 'Are you sure you want to reject the practitioner application for "${herbalist.fullName}"?\n\n'
                  '• Their status will be persisted as REJECTED in the database.',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF334155),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isVerified ? Colors.green.shade700 : Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isVerified ? 'Confirm & Grant Role' : 'Confirm Rejection'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _datasource.updateHerbalistStatus(herbalist.id, status);
      if (mounted) {
        _loadHerbalists();
        showAppErrorSnackBar(
          context,
          title: isVerified ? 'Practitioner Verified' : 'Application Rejected',
          message:
              '${herbalist.fullName} has been ${isVerified ? 'verified as licensed herbalist and persisted to database' : 'marked as rejected'}.',
          type: FailureType.validation,
        );
      }
    } catch (e, st) {
      if (mounted) {
        showAppErrorSnackBar(context, failure: ErrorHandler.handle(e, st));
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. Botanical Supplier Operations
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _loadSuppliers() async {
    setState(() {
      _loadingSuppliers = true;
      _suppliersError = null;
    });
    try {
      final results = await _datasource.getSuppliersForModeration();
      if (mounted) {
        setState(() {
          _suppliers = results;
          _loadingSuppliers = false;
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _suppliersError = ErrorHandler.handle(e, st);
          _loadingSuppliers = false;
        });
      }
    }
  }

  Future<void> _setSupplierStatus(
    SupplierModerationModel supplier,
    String status,
  ) async {
    final isVerified = status.toLowerCase() == 'verified';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isVerified ? Colors.green : Colors.red)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVerified ? Icons.storefront_rounded : Icons.cancel_outlined,
                color: isVerified ? Colors.green.shade700 : Colors.red.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isVerified
                    ? 'Grant Supplier Role & Publish'
                    : 'Reject Supplier Application',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isVerified
              ? 'Are you sure you want to approve "${supplier.supplierName}" as a verified Botanical Supplier?\n\n'
                  '• "user_profiles.is_supplier" will be set to TRUE.\n'
                  '• "supplier_profiles.verification_status" will be persisted as VERIFIED.\n'
                  '• The supplier will be published in the public Marketplace catalog.\n\n'
                  'Confirm updating and persisting to the database?'
              : 'Are you sure you want to reject the supplier application for "${supplier.supplierName}"?\n\n'
                  '• Their status will be persisted as REJECTED in the database.',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF334155),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isVerified ? Colors.green.shade700 : Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isVerified ? 'Confirm & Grant Role' : 'Confirm Rejection'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _datasource.updateSupplierStatus(supplier.id, status);
      if (mounted) {
        _loadSuppliers();
        showAppErrorSnackBar(
          context,
          title: isVerified
              ? 'Supplier Approved & Published'
              : 'Supplier Application Rejected',
          message:
              '${supplier.supplierName} has been ${isVerified ? 'approved, published, and persisted to database' : 'rejected'}.',
          type: FailureType.validation,
        );
      }
    } catch (e, st) {
      if (mounted) {
        showAppErrorSnackBar(context, failure: ErrorHandler.handle(e, st));
      }
    }
  }

  Widget _metaDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemedyDetailsSheet(RemedyModel remedy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.healing_rounded,
                            size: 32, color: Colors.teal.shade700),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              remedy.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ValidationStatusChip(
                                  status: remedy.validationStatus,
                                ),
                                if (remedy.condition != null) ...[
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.green.shade200),
                                      ),
                                      child: Text(
                                        'For: ${remedy.condition!.name}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.green.shade900,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (remedy.preparation.trim().isNotEmpty) ...[
                    const Text('Preparation Instructions:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      remedy.preparation.trim(),
                      style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (remedy.methodOfUse.trim().isNotEmpty) ...[
                    const Text('Method of Use:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      remedy.methodOfUse.trim(),
                      style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (remedy.dosageAdults != null ||
                      remedy.dosageInfants != null ||
                      remedy.duration != null ||
                      remedy.frequency != null) ...[
                    const Text('Dosage & Administration:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          if (remedy.dosageAdults != null &&
                              remedy.dosageAdults!.trim().isNotEmpty)
                            _metaDetailRow('Adult Dosage', remedy.dosageAdults!.trim()),
                          if (remedy.dosageInfants != null &&
                              remedy.dosageInfants!.trim().isNotEmpty)
                            _metaDetailRow('Infant Dosage', remedy.dosageInfants!.trim()),
                          if (remedy.frequency != null &&
                              remedy.frequency!.trim().isNotEmpty)
                            _metaDetailRow('Frequency', remedy.frequency!.trim()),
                          if (remedy.duration != null &&
                              remedy.duration!.trim().isNotEmpty)
                            _metaDetailRow('Duration', remedy.duration!.trim()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (remedy.remedyHerbs.isNotEmpty) ...[
                    Text('Herbal Ingredients (${remedy.remedyHerbs.length}):',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    ...remedy.remedyHerbs.map(
                      (rh) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.eco_rounded,
                            size: 18, color: Colors.green),
                        title: Text(rh.herb?.nameEn ?? 'Herb ${rh.herbId}'),
                        subtitle: rh.quantity != null
                            ? Text('${rh.quantity} ${rh.unit ?? ''}'.trim())
                            : (rh.preparation != null
                                ? Text(rh.preparation!)
                                : null),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (remedy.precautions != null &&
                      remedy.precautions!.trim().isNotEmpty) ...[
                    const Text('Precautions & Warnings:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      remedy.precautions!.trim(),
                      style: TextStyle(color: Colors.amber.shade900, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (remedy.sideEffects != null &&
                      remedy.sideEffects!.trim().isNotEmpty) ...[
                    const Text('Side Effects:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      remedy.sideEffects!.trim(),
                      style: TextStyle(color: Colors.red.shade800, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (remedy.moderationComments != null &&
                      remedy.moderationComments!.trim().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.feedback_outlined,
                              size: 18, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Moderation Feedback: ${remedy.moderationComments!.trim()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const Divider(),
                  const SizedBox(height: 12),
                  RecordAuditTimeline(
                    history: remedy.toEntity().auditHistory,
                    currentStatus: remedy.validationStatus,
                    title: 'Verification & Audit History',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Update Remedy'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openEditRemedy(remedy);
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteRemedy(remedy);
                        },
                      ),
                      if (remedy.validationStatus == RecordValidationStatus.submitted) ...[
                        FilledButton.icon(
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text('Start Review'),
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateRemedyStage(
                                remedy, RecordValidationStatus.underReview);
                          },
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text('Validate Remedy'),
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateRemedyStage(
                                remedy, RecordValidationStatus.validated);
                          },
                        ),
                      ] else if (remedy.validationStatus ==
                          RecordValidationStatus.underReview) ...[
                        FilledButton.icon(
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text('Validate Remedy'),
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateRemedyStage(
                                remedy, RecordValidationStatus.validated);
                          },
                        ),
                      ] else if (remedy.validationStatus ==
                          RecordValidationStatus.validated) ...[
                        FilledButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Publish to Public'),
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateRemedyStage(
                                remedy, RecordValidationStatus.published);
                          },
                        ),
                      ] else if (remedy.validationStatus ==
                          RecordValidationStatus.published) ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.visibility_off_outlined),
                          label: const Text('Unpublish'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade800),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateRemedyStage(
                                remedy, RecordValidationStatus.validated);
                          },
                        ),
                      ] else if (remedy.validationStatus ==
                          RecordValidationStatus.rejected) ...[
                        FilledButton.icon(
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('Re-open for Review'),
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateRemedyStage(
                                remedy, RecordValidationStatus.underReview);
                          },
                        ),
                      ],
                      if (remedy.validationStatus != RecordValidationStatus.rejected)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Reject Submission'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _rejectRemedyDialog(remedy);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPractitionerDetailsSheet(HerbalistModerationModel herbalist) {
    final statusColor = herbalist.isVerified
        ? Colors.green
        : (herbalist.isRejected
            ? Colors.red
            : Colors.amber.shade800);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
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
                                  fontSize: 22,
                                  color: Colors.indigo.shade800,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              herbalist.fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              herbalist.email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            PractitionerReviewCard.buildStatusBadge(
                              herbalist.verificationStatus.toUpperCase(),
                              statusColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Professional Credentials:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _metaDetailRow('Specialisation', herbalist.specialisation),
                        _metaDetailRow('Experience', '${herbalist.yearsOfExperience} years'),
                        if (herbalist.location != null)
                          _metaDetailRow('Location', herbalist.location!),
                        if (herbalist.phoneNumber != null)
                          _metaDetailRow('Phone', herbalist.phoneNumber!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!herbalist.isRejected)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _setHerbalistStatus(herbalist, 'rejected');
                          },
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
                          onPressed: () {
                            Navigator.pop(ctx);
                            _setHerbalistStatus(herbalist, 'verified');
                          },
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
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSupplierDetailsSheet(SupplierModerationModel supplier) {
    final statusColor = supplier.isVerified
        ? Colors.green
        : (supplier.isRejected
            ? Colors.red
            : Colors.amber.shade800);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: supplier.avatarUrl != null
                            ? NetworkImage(supplier.avatarUrl!)
                            : null,
                        child: supplier.avatarUrl == null
                            ? Icon(Icons.storefront_rounded,
                                size: 30, color: Colors.blue.shade800)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              supplier.supplierName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Account Owner: ${supplier.fullName} (${supplier.email})',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SupplierReviewCard.buildStatusBadge(
                              supplier.isVerified
                                  ? 'APPROVED & PUBLISHED'
                                  : (supplier.isRejected
                                      ? 'REJECTED'
                                      : 'PENDING APPROVAL'),
                              statusColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Enterprise & Supply Credentials:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _metaDetailRow('Business Name', supplier.supplierName),
                        if (supplier.location != null)
                          _metaDetailRow('Operating Facility', supplier.location!),
                        if (supplier.phoneNumber != null)
                          _metaDetailRow('Contact Phone', supplier.phoneNumber!),
                        if (supplier.bio != null && supplier.bio!.trim().isNotEmpty)
                          _metaDetailRow('Supply Details', supplier.bio!.trim()),
                        if (supplier.createdAt != null)
                          _metaDetailRow(
                            'Application Date',
                            '${supplier.createdAt!.day}/${supplier.createdAt!.month}/${supplier.createdAt!.year}',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!supplier.isRejected)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _setSupplierStatus(supplier, 'rejected');
                          },
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject Application'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (!supplier.isVerified)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _setSupplierStatus(supplier, 'verified');
                          },
                          icon: const Icon(Icons.verified, size: 16),
                          label: const Text('Approve & Publish Supplier'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rs = ResponsiveSize(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Modern surface header
            AppPageHeader(
              title: 'Moderation Hub',
              subtitle: 'Review submissions & verify medicinal catalog',
              icon: Icons.verified_user_rounded,
              onBack: widget.onBack,
            ),

            // Segmented TabBar Container
            AppBadgedTabBar(
              controller: _tabController,
              backgroundColor: Colors.white,
              margin: EdgeInsets.symmetric(
                horizontal: rs.defaultPadding,
                vertical: 4,
              ),
              tabs: [
                BadgedTabItem(
                  label: 'Herbs',
                  icon: Icons.local_florist_rounded,
                  count: _herbs
                      .where((h) =>
                          h.validationStatus == RecordValidationStatus.submitted ||
                          h.validationStatus == RecordValidationStatus.underReview)
                      .length,
                ),
                BadgedTabItem(
                  label: 'Remedies',
                  icon: Icons.healing_rounded,
                  count: _remedies
                      .where((r) =>
                          r.validationStatus == RecordValidationStatus.submitted ||
                          r.validationStatus == RecordValidationStatus.underReview)
                      .length,
                ),
                BadgedTabItem(
                  label: 'Practitioners',
                  icon: Icons.medical_services_rounded,
                  count: _herbalists
                      .where((h) => !h.isVerified && !h.isRejected)
                      .length,
                ),
                BadgedTabItem(
                  label: 'Suppliers',
                  icon: Icons.storefront_rounded,
                  count: _suppliers
                      .where((s) => !s.isVerified && !s.isRejected)
                      .length,
                ),
              ],
            ),

            // TabBarView Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHerbsTab(theme, rs),
                  _buildRemediesTab(theme, rs),
                  _buildPractitionersTab(theme, rs),
                  _buildSuppliersTab(theme, rs),
                ],
              ),
            ),
          ],
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
        'pending' => h.validationStatus == RecordValidationStatus.submitted ||
            h.validationStatus == RecordValidationStatus.underReview,
        'validated' => h.validationStatus == RecordValidationStatus.validated,
        'published' => h.validationStatus == RecordValidationStatus.published,
        'rejected' => h.validationStatus == RecordValidationStatus.rejected,
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
                AppSearchBar(
                  hintText: 'Search herbs by English, Shona or Ndebele name...',
                  onChanged: (val) => setState(() => _herbSearchQuery = val),
                ),
                const SizedBox(height: 8),
                AppFilterBar<String>(
                  selectedValue: _herbFilter,
                  onSelected: (v) => setState(() => _herbFilter = v),
                  options: [
                    FilterOption(
                      label: 'All',
                      value: 'all',
                      count: _herbs.length,
                    ),
                    FilterOption(
                      label: 'Pending',
                      value: 'pending',
                      count: _herbs.where((h) =>
                          h.validationStatus == RecordValidationStatus.submitted ||
                          h.validationStatus == RecordValidationStatus.underReview).length,
                      activeColor: const Color(0xFFD97706),
                    ),
                    FilterOption(
                      label: 'Validated',
                      value: 'validated',
                      count: _herbs.where((h) =>
                          h.validationStatus == RecordValidationStatus.validated).length,
                      activeColor: const Color(0xFF0284C7),
                    ),
                    FilterOption(
                      label: 'Published',
                      value: 'published',
                      count: _herbs.where((h) =>
                          h.validationStatus == RecordValidationStatus.published).length,
                      activeColor: const Color(0xFF16A34A),
                    ),
                    FilterOption(
                      label: 'Rejected',
                      value: 'rejected',
                      count: _herbs.where((h) =>
                          h.validationStatus == RecordValidationStatus.rejected).length,
                      activeColor: const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 54,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No herbs found matching criteria.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _herbFilter == 'pending'
                              ? 'All herbs have been reviewed and verified!'
                              : 'Try adjusting your search or filter.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: rs.defaultPadding),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final herb = filtered[index];
                      return HerbReviewCard(
                        herb: herb,
                        onTap: () => _showHerbDetailsSheet(herb),
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
        'pending' => r.validationStatus == RecordValidationStatus.submitted ||
            r.validationStatus == RecordValidationStatus.underReview,
        'validated' => r.validationStatus == RecordValidationStatus.validated,
        'published' => r.validationStatus == RecordValidationStatus.published,
        'rejected' => r.validationStatus == RecordValidationStatus.rejected,
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
                AppSearchBar(
                  hintText: 'Search remedies by name or condition...',
                  onChanged: (val) => setState(() => _remedySearchQuery = val),
                ),
                const SizedBox(height: 8),
                AppFilterBar<String>(
                  selectedValue: _remedyFilter,
                  onSelected: (v) => setState(() => _remedyFilter = v),
                  options: [
                    FilterOption(
                      label: 'All',
                      value: 'all',
                      count: _remedies.length,
                    ),
                    FilterOption(
                      label: 'Pending',
                      value: 'pending',
                      count: _remedies.where((r) =>
                          r.validationStatus == RecordValidationStatus.submitted ||
                          r.validationStatus == RecordValidationStatus.underReview).length,
                      activeColor: const Color(0xFFD97706),
                    ),
                    FilterOption(
                      label: 'Validated',
                      value: 'validated',
                      count: _remedies.where((r) =>
                          r.validationStatus == RecordValidationStatus.validated).length,
                      activeColor: const Color(0xFF0284C7),
                    ),
                    FilterOption(
                      label: 'Published',
                      value: 'published',
                      count: _remedies.where((r) =>
                          r.validationStatus == RecordValidationStatus.published).length,
                      activeColor: const Color(0xFF16A34A),
                    ),
                    FilterOption(
                      label: 'Rejected',
                      value: 'rejected',
                      count: _remedies.where((r) =>
                          r.validationStatus == RecordValidationStatus.rejected).length,
                      activeColor: const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 54,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No remedies found matching criteria.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _remedyFilter == 'pending'
                              ? 'All remedies have been reviewed and verified!'
                              : 'Try adjusting your search or filter.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: rs.defaultPadding),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final remedy = filtered[index];
                      return RemedyReviewCard(
                        remedy: remedy,
                        onTap: () => _showRemedyDetailsSheet(remedy),
                        onToggleApproval: () {
                          final isApproved = remedy.isApproved ||
                              remedy.validationStatus.isApproved;
                          _updateRemedyStage(
                            remedy,
                            isApproved
                                ? RecordValidationStatus.submitted
                                : RecordValidationStatus.published,
                          );
                        },
                        onReject: () => _rejectRemedyDialog(remedy),
                        onEdit: () => _openEditRemedy(remedy),
                        onDelete: () => _deleteRemedy(remedy),
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
                AppSearchBar(
                  hintText: 'Search practitioners by name, email, specialty, location...',
                  onChanged: (val) =>
                      setState(() => _herbalistSearchQuery = val),
                ),
                const SizedBox(height: 8),
                AppFilterBar<String>(
                  selectedValue: _herbalistFilter,
                  onSelected: (v) => setState(() => _herbalistFilter = v),
                  options: [
                    FilterOption(
                      label: 'All',
                      value: 'all',
                      count: _herbalists.length,
                    ),
                    FilterOption(
                      label: 'Pending',
                      value: 'pending',
                      count: _herbalists.where((h) => h.isPending).length,
                      activeColor: Colors.amber.shade800,
                    ),
                    FilterOption(
                      label: 'Verified',
                      value: 'verified',
                      count: _herbalists.where((h) => h.isVerified).length,
                      activeColor: Colors.green.shade700,
                    ),
                    FilterOption(
                      label: 'Rejected',
                      value: 'rejected',
                      count: _herbalists.where((h) => h.isRejected).length,
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
                      return PractitionerReviewCard(
                        herbalist: herbalist,
                        onTap: () =>
                            _showPractitionerDetailsSheet(herbalist),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab 4: Suppliers / Vendor Profiles View
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSuppliersTab(ThemeData theme, ResponsiveSize rs) {
    if (_loadingSuppliers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_suppliersError != null) {
      return AppErrorView(
        failure: _suppliersError,
        onRetry: _loadSuppliers,
      );
    }

    final filtered = _suppliers.where((s) {
      final q = _supplierSearchQuery.toLowerCase();
      final matchesSearch = s.supplierName.toLowerCase().contains(q) ||
          s.fullName.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          (s.location?.toLowerCase().contains(q) ?? false) ||
          (s.bio?.toLowerCase().contains(q) ?? false);

      final matchesFilter = switch (_supplierFilter) {
        'pending' => s.isPending,
        'verified' => s.isVerified,
        'rejected' => s.isRejected,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadSuppliers,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(rs.defaultPadding),
            child: Column(
              children: [
                AppSearchBar(
                  hintText: 'Search suppliers by business, owner, location, products...',
                  onChanged: (val) =>
                      setState(() => _supplierSearchQuery = val),
                ),
                const SizedBox(height: 8),
                AppFilterBar<String>(
                  selectedValue: _supplierFilter,
                  onSelected: (v) => setState(() => _supplierFilter = v),
                  options: [
                    FilterOption(
                      label: 'All',
                      value: 'all',
                      count: _suppliers.length,
                    ),
                    FilterOption(
                      label: 'Pending',
                      value: 'pending',
                      count: _suppliers.where((s) => s.isPending).length,
                      activeColor: Colors.amber.shade800,
                    ),
                    FilterOption(
                      label: 'Approved & Published',
                      value: 'verified',
                      count: _suppliers.where((s) => s.isVerified).length,
                      activeColor: Colors.green.shade700,
                    ),
                    FilterOption(
                      label: 'Rejected',
                      value: 'rejected',
                      count: _suppliers.where((s) => s.isRejected).length,
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
                    child: Text('No botanical supplier profiles matching criteria.'),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: rs.defaultPadding),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final supplier = filtered[index];
                      return SupplierReviewCard(
                        supplier: supplier,
                        onTap: () => _showSupplierDetailsSheet(supplier),
                        onAction: () => _showSupplierDetailsSheet(supplier),
                        actionLabel: supplier.isVerified ? 'Manage' : 'Review',
                        actionIcon: supplier.isVerified
                            ? Icons.verified
                            : Icons.rate_review_outlined,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
