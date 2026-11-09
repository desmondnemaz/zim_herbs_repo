import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:zim_herbs_repo/features/repository/herbs/data/datasources/herb_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/repositories/herb_repository_impl.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/cubit/herb_detail_cubit.dart';

import 'package:zim_herbs_repo/features/repository/remedies/data/datasources/remedy_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/remedies/data/repositories/remedy_repository_impl.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/pages/remedies_list.dart';

import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/components/app_page_app_bar.dart';
import 'package:zim_herbs_repo/core/components/record_audit_timeline.dart';
import 'package:zim_herbs_repo/core/components/validation_status_chip.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/admin/herb_management/presentation/add_edit_herb_page.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/models/herb_model.dart';

class HerbDetailsPage extends StatefulWidget {
  final String herbId;
  final bool isPublicView;

  const HerbDetailsPage({
    super.key,
    required this.herbId,
    this.isPublicView = false,
  });

  @override
  State<HerbDetailsPage> createState() => _HerbDetailsPageState();
}

class _HerbDetailsPageState extends State<HerbDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _scrollController = ScrollController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openEditHerb(BuildContext context, Herb herb) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditHerbPage(
          herb: HerbModel.fromEntity(herb),
        ),
      ),
    );

    if (result == true && mounted && context.mounted) {
      context.read<HerbDetailCubit>().loadHerb(widget.herbId);
    }
  }

  Future<void> _handlePublishHerb(
    BuildContext context,
    Herb herb,
    String? currentUserId,
  ) async {
    final client = Supabase.instance.client;
    final ds = HerbRemoteDataSource(client);
    await ds.updateHerbVerification(
      herb.id,
      true,
      verifiedBy: currentUserId,
      status: RecordValidationStatus.published,
    );
    if (context.mounted) {
      context.read<HerbDetailCubit>().loadHerb(herb.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Published "${herb.nameEn}" successfully'),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
    }
  }

  Future<void> _showUnpublishHerbDialog(
    BuildContext context,
    Herb herb,
    String? currentUserId,
  ) async {
    RecordValidationStatus selectedTarget = RecordValidationStatus.validated;
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.unpublished_outlined, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              const Text('Unpublish Herb'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unpublishing "${herb.nameEn}" will immediately hide it from public users and catalogs.',
                  style: const TextStyle(fontSize: 13.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reason for Unpublishing:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Updating dosage guidelines or safety contraindications...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Target Status:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                RadioGroup<RecordValidationStatus>(
                  groupValue: selectedTarget,
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedTarget = val);
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<RecordValidationStatus>(
                        title: const Text('Validated (Hold)'),
                        subtitle: const Text(
                            'Keeps botanical review intact; hides from public'),
                        value: RecordValidationStatus.validated,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<RecordValidationStatus>(
                        title: const Text('Under Review (Re-evaluate)'),
                        subtitle: const Text(
                            'Sends back to the moderation queue for revisions'),
                        value: RecordValidationStatus.underReview,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<RecordValidationStatus>(
                        title: const Text('Archived (Decommission)'),
                        subtitle: const Text(
                            'Permanently retired from active repository'),
                        value: RecordValidationStatus.archived,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade800),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Confirm Unpublish'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final client = Supabase.instance.client;
      final ds = HerbRemoteDataSource(client);
      await ds.unpublishHerb(
        herb.id,
        targetStatus: selectedTarget,
        moderatorId: currentUserId,
        reason: reasonController.text,
      );
      if (context.mounted) {
        context.read<HerbDetailCubit>().loadHerb(herb.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Unpublished "${herb.nameEn}" (${selectedTarget.label})'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    return BlocProvider(
      create: (context) {
        final client = Supabase.instance.client;
        final dataSource = HerbRemoteDataSource(client);
        final herbRepository = HerbRepositoryImpl(dataSource);
        return HerbDetailCubit(
          herbRepository: herbRepository,
          remedyRepository: RemedyRepositoryImpl(
            RemedyRemoteDataSource(client),
          ),
        )..loadHerb(widget.herbId);
      },
      child: BlocBuilder<HerbDetailCubit, HerbDetailState>(
        builder: (context, state) {
          // ============================================================
          // LOADING
          // ============================================================
          if (state is HerbDetailInitial || state is HerbDetailLoading) {
            return Scaffold(
              appBar: AppPageAppBar(
                title: 'Herb Details',
                onBack: Navigator.canPop(context)
                    ? () => Navigator.pop(context)
                    : null,
              ),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // ============================================================
          // ERROR
          // ============================================================
          if (state is HerbDetailError) {
            return Scaffold(
              appBar: AppPageAppBar(
                title: 'Herb Details',
                onBack: Navigator.canPop(context)
                    ? () => Navigator.pop(context)
                    : null,
              ),
              body: AppErrorView(
                failure: state.failure,
                message: state.message,
                onRetry: () {
                  context.read<HerbDetailCubit>().loadHerb(widget.herbId);
                },
                onBack: Navigator.canPop(context)
                    ? () => Navigator.pop(context)
                    : null,
              ),
            );
          }

          // ============================================================
          // LOADED
          // ============================================================
          if (state is HerbDetailLoaded) {
            final herb = state.herb;
            final treatments = state.treatments;

            AuthState? authState;
            try {
              authState = context.watch<AuthCubit>().state;
            } catch (_) {}
            final authUser = authState is Authenticated ? authState.user : null;
            final canModerate =
                !widget.isPublicView && authUser != null && authUser.canModerate;
            final canEdit = !widget.isPublicView &&
                authUser != null &&
                (authUser.canModerate ||
                    (herb.createdBy != null &&
                        authUser.id == herb.createdBy));

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppPageAppBar(
                title: herb.nameEn,
                onBack: Navigator.canPop(context)
                    ? () => Navigator.pop(context)
                    : null,
                actions: [
                  if (canModerate) ...[
                    if (herb.isPublished)
                      IconButton(
                        tooltip: 'Unpublish Herb',
                        icon: const Icon(
                          Icons.unpublished_outlined,
                          color: Colors.orange,
                        ),
                        onPressed: () => _showUnpublishHerbDialog(
                          context,
                          herb,
                          authUser.id,
                        ),
                      )
                    else
                      IconButton(
                        tooltip: 'Publish Herb',
                        icon: const Icon(
                          Icons.publish_rounded,
                          color: Color(0xFF15803D),
                        ),
                        onPressed: () => _handlePublishHerb(
                          context,
                          herb,
                          authUser.id,
                        ),
                      ),
                  ],
                  IconButton(
                    tooltip: 'Refresh Herb Data',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () {
                      context.read<HerbDetailCubit>().loadHerb(widget.herbId);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              // Mobile & Tablet: Sticky Bottom Action Bar (Admin / Contributor only)
              bottomNavigationBar: (canEdit && !Responsive.isDesktop(context))
                  ? _buildMobileStickyActionBar(context, herb, canEdit)
                  : null,
              body: Stack(
                children: [
                  // Scrollable Main Content
                  Positioned.fill(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.isMobile(context) ? 16 : 32,
                        vertical: 24,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: Responsive.isMobile(context)
                                    ? double.infinity
                                    : Responsive.isTablet(context)
                                        ? 750
                                        : 820,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Rejection / Moderation Notice Card (if applicable & not in public view)
                                  if (!widget.isPublicView &&
                                      herb.rejectionReason != null &&
                                      herb.rejectionReason!.trim().isNotEmpty) ...[
                                    _buildModerationNoticeCard(
                                      herb.rejectionReason!,
                                      rs,
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  // Herb Image Showcase (Clean, no text overlay)
                                  _buildImageShowcase(context, herb, rs),

                                  const SizedBox(height: 20),

                                  // Herb Names & Language Badges Section (with fallbacks)
                                  _buildNamesSection(herb, rs),

                                  const SizedBox(height: 24),

                                  // Botanical Profile Card
                                  _buildBotanicalProfileCard(herb, rs),

                                  const SizedBox(height: 24),

                                  // Description Section (with fallback for empty field)
                                  _buildSectionCard(
                                    icon: Icons.info_outline_rounded,
                                    title: 'About this Herb',
                                    content: (herb.description != null &&
                                            herb.description!.trim().isNotEmpty)
                                        ? Text(
                                            herb.description!,
                                            style: TextStyle(
                                              fontSize: rs.bodyFont,
                                              height: 1.6,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.85),
                                            ),
                                          )
                                        : Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.notes_rounded,
                                                size: 20,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.35),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'No botanical or medicinal description has been recorded for this herb yet.',
                                                  style: TextStyle(
                                                    fontSize: rs.bodyFont,
                                                    fontStyle: FontStyle.italic,
                                                    height: 1.5,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(alpha: 0.55),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                    rs: rs,
                                  ),

                                  const SizedBox(height: 24),

                                  // Treatable Ailments Section (with fallback for empty field)
                                  _buildSectionCard(
                                    icon: Icons.medical_services_rounded,
                                    title: 'Treatable Ailments',
                                    content: treatments.isNotEmpty
                                        ? Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: treatments
                                                .where((treatment) =>
                                                    treatment.conditionName !=
                                                        null &&
                                                    (treatment.isApproved ||
                                                        treatment.validationStatus
                                                            .isApproved))
                                                .map((treatment) => (
                                                      id: treatment
                                                          .conditionId,
                                                      name: treatment
                                                          .conditionName!
                                                    ))
                                                .toSet()
                                                .map(
                                                  (cond) => _ConditionBadge(
                                                    name: cond.name,
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              RemediesList(
                                                            initialConditionId:
                                                                cond.id,
                                                            isPublicView: widget
                                                                .isPublicView,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                                .toList(),
                                          )
                                        : Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.healing_outlined,
                                                size: 20,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                                    .withValues(alpha: 0.5),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'No treatable health ailments or remedies have been linked to this herb yet. Verified treatments will appear here once linked.',
                                                  style: TextStyle(
                                                    fontSize: rs.bodyFont,
                                                    fontStyle: FontStyle.italic,
                                                    height: 1.5,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(alpha: 0.55),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                    rs: rs,
                                    accentColor: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                  ),

                                  const SizedBox(height: 24),

                                  // Other Traditional & Practical Uses (Food, Construction, Firewood, Cultural, Ritual)
                                  _buildOtherUsesSection(herb, rs),

                                  if (herb.caution != null &&
                                      herb.caution!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 24),
                                    _buildSectionCard(
                                      icon: Icons.warning_amber_rounded,
                                      title: 'Caution & Warnings',
                                      content: Text(
                                        herb.caution!.trim(),
                                        style: TextStyle(
                                          fontSize: rs.bodyFont,
                                          height: 1.6,
                                          color: const Color(0xFF9A3412),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      rs: rs,
                                      accentColor: const Color(0xFFEA580C),
                                    ),
                                  ],

                                  if (herb.source != null &&
                                      herb.source!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 24),
                                    _buildSectionCard(
                                      icon: Icons.menu_book_rounded,
                                      title: 'Sources & References',
                                      content: Text(
                                        herb.source!.trim(),
                                        style: TextStyle(
                                          fontSize: rs.bodyFont,
                                          height: 1.6,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.85),
                                        ),
                                      ),
                                      rs: rs,
                                      accentColor: const Color(0xFF0D9488),
                                    ),
                                  ],

                                  if (!widget.isPublicView) ...[
                                    const SizedBox(height: 24),

                                    // Audit and Verification Timeline (Admin / Contributor only)
                                    RecordAuditTimeline(
                                      history: herb.auditHistory,
                                      currentStatus: herb.validationStatus,
                                      title: 'Herb Validation & History',
                                    ),
                                  ],

                                  const SizedBox(height: 80),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ALWAYS FLOATING BUTTONS ON DESKTOP (Admin / Contributor only)
                  if (canEdit && Responsive.isDesktop(context))
                    Positioned(
                      top: 24,
                      right: 28,
                      child: _buildDesktopFloatingActionPanel(
                        context,
                        herb,
                        canEdit,
                      ),
                    ),
                ],
              ),
            );
          }

          // Fallback
          return const Scaffold(
            body: SizedBox.shrink(),
          );
        },
      ),
    );
  }

  // ========================================================================
  // REJECTION / MODERATION NOTICE CARD
  // ========================================================================

  Widget _buildModerationNoticeCard(String notes, ResponsiveSize rs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.report_problem_rounded, color: Colors.red.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moderation Notice / Rejection Reason',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notes,
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // IMAGE SHOWCASE (Clean without text overlay + Meaningful fallback)
  // ========================================================================

  Widget _buildImageShowcase(
    BuildContext context,
    Herb herb,
    ResponsiveSize rs,
  ) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    final imageHeight = isMobile ? 260.0 : 360.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: 'herb-image-${herb.nameEn}',
          child: Container(
            height: imageHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              boxShadow: [
                BoxShadow(
                  blurRadius: 16,
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (herb.images.isNotEmpty)
                    Image.network(
                      herb.images[_currentImageIndex.clamp(
                              0, herb.images.length - 1)]
                          .imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.spa_rounded,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.5),
                            size: 64,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.spa_rounded,
                            size: 56,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No Herb Image Uploaded',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.8),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (!widget.isPublicView) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Tap "Edit Herb" to contribute photographs',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Subtle gradient shadow at bottom for depth
                  if (herb.images.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.25),
                              ],
                              stops: const [0.75, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Image counter badge when multiple images exist
                  if (herb.images.length > 1)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white24,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${herb.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Thumbnails Row
        if (herb.images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: herb.images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = _currentImageIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.2),
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Opacity(
                        opacity: isSelected ? 1.0 : 0.65,
                        child: Image.network(
                          herb.images[index].imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // ========================================================================
  // HERB NAMES & LANGUAGE BADGES (With meaningful fallbacks)
  // ========================================================================

  Widget _buildNamesSection(
    Herb herb,
    ResponsiveSize rs,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      herb.nameEn,
                      style: TextStyle(
                        fontSize: rs.titleFont * 1.3,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (herb.scientificName != null &&
                        herb.scientificName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        herb.scientificName!,
                        style: TextStyle(
                          fontSize: rs.titleFont * 0.9,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ValidationStatusChip(
                status: herb.validationStatus,
                isOutlined: false,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // English
              _buildLanguageBadge(
                icon: Icons.language_rounded,
                label: 'English',
                value: herb.nameEn,
                color: theme.colorScheme.primary,
                rs: rs,
              ),

              // Shona (with meaningful fallback if missing)
              _buildLanguageBadge(
                icon: Icons.translate_rounded,
                label: 'Shona',
                value: (herb.nameSn != null && herb.nameSn!.trim().isNotEmpty)
                    ? herb.nameSn!
                    : 'Not specified',
                isFallback:
                    herb.nameSn == null || herb.nameSn!.trim().isEmpty,
                color: Colors.teal.shade700,
                rs: rs,
              ),

              // Ndebele (with meaningful fallback if missing)
              _buildLanguageBadge(
                icon: Icons.translate_rounded,
                label: 'Ndebele',
                value: (herb.nameNd != null && herb.nameNd!.trim().isNotEmpty)
                    ? herb.nameNd!
                    : 'Not specified',
                isFallback:
                    herb.nameNd == null || herb.nameNd!.trim().isEmpty,
                color: Colors.indigo.shade700,
                rs: rs,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ResponsiveSize rs,
    bool isFallback = false,
  }) {
    final effectiveColor =
        isFallback ? Colors.grey.shade600 : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: isFallback ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: effectiveColor.withValues(alpha: isFallback ? 0.18 : 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: effectiveColor),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: rs.labelFont,
              fontWeight: FontWeight.w700,
              color: effectiveColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: rs.labelFont,
              fontWeight: isFallback ? FontWeight.normal : FontWeight.w500,
              fontStyle: isFallback ? FontStyle.italic : FontStyle.normal,
              color: isFallback
                  ? Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // MOBILE / TABLET STICKY BOTTOM ACTION BAR
  // ========================================================================

  Widget _buildMobileStickyActionBar(
    BuildContext context,
    Herb herb,
    bool canEdit,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(Icons.edit_note_rounded, size: 20),
          label: Text(
            canEdit ? 'Edit Herb Details' : 'View Only',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: canEdit
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.12),
            foregroundColor: canEdit
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withValues(alpha: 0.38),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: canEdit ? () => _openEditHerb(context, herb) : null,
        ),
      ),
    );
  }

  // ========================================================================
  // DESKTOP ALWAYS FLOATING ACTION BUTTON (Right Margin)
  // ========================================================================

  Widget _buildDesktopFloatingActionPanel(
    BuildContext context,
    Herb herb,
    bool canEdit,
  ) {
    final theme = Theme.of(context);

    return FilledButton.icon(
      icon: const Icon(Icons.edit_note_rounded, size: 20),
      label: const Text(
        'Edit Herb',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: canEdit
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.12),
        foregroundColor: canEdit
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface.withValues(alpha: 0.38),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        elevation: 4,
        shadowColor: theme.colorScheme.primary.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: canEdit ? () => _openEditHerb(context, herb) : null,
    );
  }

  // ========================================================================
  // SECTION CARD
  // ========================================================================

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget content,
    required ResponsiveSize rs,
    Color? accentColor,
  }) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: rs.titleFont,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

// ==========================================================================
// BOTANICAL PROFILE CARD & OTHER USES SECTION
// ==========================================================================

  Widget _buildBotanicalProfileCard(Herb herb, ResponsiveSize rs) {
    final theme = Theme.of(context);
    final hasBotanicalData = (herb.scientificName != null && herb.scientificName!.isNotEmpty) ||
        (herb.family != null && herb.family!.isNotEmpty) ||
        (herb.growthHabit != null && herb.growthHabit!.isNotEmpty) ||
        (herb.placesFound != null && herb.placesFound!.isNotEmpty) ||
        herb.partsUsed.isNotEmpty;

    if (!hasBotanicalData) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.biotech_rounded,
                  color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Botanical Profile & Habitat',
                style: TextStyle(
                  fontSize: rs.subtitleFont,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Metadata Grid/Wrap
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              if (herb.family != null && herb.family!.isNotEmpty)
                _buildBotanicalTag(
                  icon: Icons.category_rounded,
                  label: 'Family',
                  value: herb.family!,
                  theme: theme,
                ),
              if (herb.growthHabit != null && herb.growthHabit!.isNotEmpty)
                _buildBotanicalTag(
                  icon: Icons.nature_rounded,
                  label: 'Growth Habit',
                  value: herb.growthHabit!,
                  theme: theme,
                ),
              if (herb.exoticStatus != null && herb.exoticStatus!.isNotEmpty)
                _buildBotanicalTag(
                  icon: Icons.eco_rounded,
                  label: 'Exotic Status',
                  value: herb.exoticStatus!,
                  theme: theme,
                ),
            ],
          ),

          // Where Found / Places Found
          if (herb.placesFound != null && herb.placesFound!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: Color(0xFFE65100), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Places Where Found',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          herb.placesFound!,
                          style: TextStyle(
                            fontSize: rs.bodyFont * 0.95,
                            color: const Color(0xFF334155),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Parts Used
          if (herb.partsUsed.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.grass_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parts Used',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: herb.partsUsed.map((part) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              part,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBotanicalTag({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherUsesSection(Herb herb, ResponsiveSize rs) {
    final theme = Theme.of(context);
    final uses = herb.otherUses;
    final hasNotes = herb.otherUsesNotes != null &&
        herb.otherUsesNotes!.trim().isNotEmpty;
    final hasUses = uses.isNotEmpty || hasNotes;

    return _buildSectionCard(
      icon: Icons.volunteer_activism_rounded,
      title: 'Traditional & Practical Uses (Non-Medicinal)',
      content: hasUses
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasNotes) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.notes_rounded,
                              size: 18, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Other Uses & Notes',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                herb.otherUsesNotes!.trim(),
                                style: TextStyle(
                                  fontSize: rs.bodyFont * 0.95,
                                  color: const Color(0xFF334155),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ...uses.map((use) {
                  return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(use.categoryIcon,
                            size: 18, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  use.categoryLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                if (use.title != null &&
                                    use.title != use.categoryLabel) ...[
                                  Text(
                                    ' • ${use.title!}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              use.description,
                              style: TextStyle(
                                fontSize: rs.bodyFont * 0.95,
                                color: const Color(0xFF334155),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.spa_outlined,
                  size: 20,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No non-medicinal cultural, culinary, or practical uses have been recorded for this herb yet.',
                    style: TextStyle(
                      fontSize: rs.bodyFont,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
      rs: rs,
      accentColor: const Color(0xFF795548),
    );
  }
}

// ==========================================================================
// CONDITION BADGE
// ==========================================================================

class _ConditionBadge extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _ConditionBadge({
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.teal.withValues(
                alpha: 0.3,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.healing_rounded,
                size: 16,
                color: Colors.teal,
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}