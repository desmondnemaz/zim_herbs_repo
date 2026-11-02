import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:zim_herbs_repo/features/repository/conditions/data/datasources/condition_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/models/condition_model.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/repositories/condition_repository_impl.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/entities/condition.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/cubit/condition_detail_cubit.dart';
import 'package:zim_herbs_repo/features/admin/condition_management/presentation/components/add_edit_condition_dialog.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';

import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/components/app_page_app_bar.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';

class ConditionDetailsPage extends StatefulWidget {
  final String conditionId;

  const ConditionDetailsPage({super.key, required this.conditionId});

  @override
  State<ConditionDetailsPage> createState() => _ConditionDetailsPageState();
}

class _ConditionDetailsPageState extends State<ConditionDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _scrollController = ScrollController();

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
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openEditCondition(
    BuildContext context,
    Condition condition,
  ) async {
    final client = Supabase.instance.client;
    final dataSource = ConditionRemoteDataSource(client);
    final repository = ConditionRepositoryImpl(dataSource);

    await showDialog(
      context: context,
      builder: (dialogContext) => AddEditConditionDialog(
        condition: ConditionModel.fromEntity(condition),
        onSave: (updatedConditionModel) async {
          final bodyPartIds = updatedConditionModel.bodyParts
              .map((bp) => bp.id)
              .toList();
          await repository.updateCondition(
            updatedConditionModel.toEntity(),
            bodyPartIds: bodyPartIds,
          );
          if (context.mounted) {
            context
                .read<ConditionDetailCubit>()
                .loadCondition(widget.conditionId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Condition updated successfully'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    return BlocProvider(
      create: (context) {
        final client = Supabase.instance.client;
        final dataSource = ConditionRemoteDataSource(client);
        final repository = ConditionRepositoryImpl(dataSource);
        return ConditionDetailCubit(repository)
          ..loadCondition(widget.conditionId);
      },
      child: BlocBuilder<ConditionDetailCubit, ConditionDetailState>(
        builder: (context, state) {
          // ============================================================
          // LOADING
          // ============================================================
          if (state is ConditionDetailLoading ||
              state is ConditionDetailInitial) {
            return Scaffold(
              appBar: AppPageAppBar(
                title: 'Condition Details',
                onBack: Navigator.canPop(context)
                    ? () => Navigator.pop(context)
                    : null,
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          // ============================================================
          // ERROR
          // ============================================================
          if (state is ConditionDetailError) {
            return Scaffold(
              appBar: AppPageAppBar(
                title: 'Condition Details',
                onBack: Navigator.canPop(context)
                    ? () => Navigator.pop(context)
                    : null,
              ),
              body: AppErrorView(
                failure: state.failure,
                message: state.message,
                onRetry: () => context
                    .read<ConditionDetailCubit>()
                    .loadCondition(widget.conditionId),
                onBack: Navigator.canPop(context)
                    ? () => Navigator.pop(context)
                    : null,
              ),
            );
          }

          // ============================================================
          // LOADED
          // ============================================================
          if (state is ConditionDetailLoaded) {
            final condition = state.condition;
            final systemColor = getBodySystemColor(condition.bodySystem);

            AuthState? authState;
            try {
              authState = context.watch<AuthCubit>().state;
            } catch (_) {}
            final canEdit =
                authState is Authenticated && authState.user.canModerate;

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppPageAppBar(
                title: condition.name,
                onBack: Navigator.canPop(context)
                    ? () => Navigator.pop(context)
                    : null,
                actions: [
                  IconButton(
                    tooltip: 'Refresh Condition Data',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () {
                      context
                          .read<ConditionDetailCubit>()
                          .loadCondition(widget.conditionId);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              // Mobile / Tablet: Sticky Bottom Action Bar
              bottomNavigationBar: !Responsive.isDesktop(context)
                  ? _buildMobileStickyActionBar(context, condition, canEdit)
                  : null,
              body: Stack(
                children: [
                  // Main Scrollable Content
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
                                  // Condition Hero Header Showcase (Clean, no text overlay)
                                  _buildConditionHeroShowcase(
                                    condition,
                                    systemColor,
                                    rs,
                                  ),

                                  const SizedBox(height: 24),

                                  // Affected Body Parts Section (with meaningful fallback)
                                  _buildSectionCard(
                                    icon: Icons.accessibility_new_rounded,
                                    title: 'Affected Body Parts',
                                    content: condition.bodyParts.isNotEmpty
                                        ? Text(
                                            condition.bodyParts
                                                .map((bp) => bp.localizedName)
                                                .join(', '),
                                            style: TextStyle(
                                              fontSize: rs.bodyFont,
                                              height: 1.6,
                                              fontWeight: FontWeight.w500,
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
                                                Icons.accessibility_new_outlined,
                                                size: 20,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.35),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'No specific body parts or organs have been linked to this condition yet. Tap "Edit Condition" to specify affected anatomy.',
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

                                  // Clinical Description Section (with meaningful fallback)
                                  _buildSectionCard(
                                    icon: Icons.info_outline_rounded,
                                    title: 'Clinical Description',
                                    content: (condition.description != null &&
                                            condition.description!
                                                .trim()
                                                .isNotEmpty)
                                        ? Text(
                                            condition.description!,
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
                                                  'No clinical or traditional overview has been documented for this condition yet. Contributors and moderators can add detailed diagnostic notes by editing this record.',
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

                                  // Common Symptoms Section (with meaningful fallback)
                                  _buildSectionCard(
                                    icon: Icons.warning_amber_rounded,
                                    title: 'Common Symptoms',
                                    content: condition.symptoms.isNotEmpty
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: condition.symptoms
                                                .map(
                                                  (s) => _buildBulletPoint(
                                                    s,
                                                    rs,
                                                    context,
                                                  ),
                                                )
                                                .toList(),
                                          )
                                        : Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.checklist_rounded,
                                                size: 20,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.35),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'No specific symptoms have been cataloged for this condition yet. Symptoms help identify when to recommend traditional herbal remedies.',
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

                                  // Precautions & Care Section (with meaningful fallback)
                                  _buildSectionCard(
                                    icon: Icons.health_and_safety_outlined,
                                    title: 'Precautions & Care',
                                    content: condition.precautions.isNotEmpty
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: condition.precautions
                                                .map(
                                                  (p) => _buildBulletPoint(
                                                    p,
                                                    rs,
                                                    context,
                                                  ),
                                                )
                                                .toList(),
                                          )
                                        : Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.shield_outlined,
                                                size: 20,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.35),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'No standard lifestyle precautions or care recommendations have been noted for this condition yet.',
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

                                  const SizedBox(height: 80),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ALWAYS FLOATING BUTTONS ON DESKTOP (Right Margin)
                  if (Responsive.isDesktop(context))
                    Positioned(
                      top: 24,
                      right: 28,
                      child: _buildDesktopFloatingActionPanel(
                        context,
                        condition,
                        canEdit,
                      ),
                    ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ========================================================================
  // CONDITION HERO SHOWCASE (Clean without text overlay)
  // ========================================================================

  Widget _buildConditionHeroShowcase(
    Condition condition,
    Color systemColor,
    ResponsiveSize rs,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: systemColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: systemColor.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Body System SVG Icon Circle
          CircleAvatar(
            radius: rs.icon * 1.5,
            backgroundColor: systemColor.withValues(alpha: 0.16),
            child: SvgPicture.asset(
              getBodySystemSvg(condition.bodySystem),
              width: rs.icon * 1.6,
              height: rs.icon * 1.6,
              colorFilter: ColorFilter.mode(
                systemColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Titles & Metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  condition.name,
                  style: TextStyle(
                    fontSize: rs.titleFont * 1.35,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // System Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: systemColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.category_outlined,
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            bodySystemLabel(condition.bodySystem),
                            style: TextStyle(
                              fontSize: rs.labelFont,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body Parts Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: systemColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.accessibility_new_rounded,
                            size: 15,
                            color: systemColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            condition.bodyParts.isNotEmpty
                                ? '${condition.bodyParts.length} Parts Linked'
                                : 'No Anatomy Linked',
                            style: TextStyle(
                              fontSize: rs.labelFont,
                              color: systemColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // DESKTOP ALWAYS FLOATING ACTION BUTTON (Right Margin)
  // ========================================================================

  Widget _buildDesktopFloatingActionPanel(
    BuildContext context,
    Condition condition,
    bool canEdit,
  ) {
    final theme = Theme.of(context);

    return FilledButton.icon(
      icon: const Icon(Icons.edit_note_rounded, size: 20),
      label: const Text(
        'Edit Condition',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: canEdit
            ? const Color(0xFF106F74)
            : theme.colorScheme.onSurface.withValues(alpha: 0.12),
        foregroundColor: canEdit
            ? Colors.white
            : theme.colorScheme.onSurface.withValues(alpha: 0.38),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        elevation: 4,
        shadowColor: const Color(0xFF106F74).withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: canEdit ? () => _openEditCondition(context, condition) : null,
    );
  }

  // ========================================================================
  // MOBILE / TABLET STICKY BOTTOM ACTION BAR
  // ========================================================================

  Widget _buildMobileStickyActionBar(
    BuildContext context,
    Condition condition,
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
            canEdit ? 'Edit Condition Details' : 'View Only',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: canEdit
                ? const Color(0xFF106F74)
                : theme.colorScheme.onSurface.withValues(alpha: 0.12),
            foregroundColor: canEdit
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.38),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed:
              canEdit ? () => _openEditCondition(context, condition) : null,
        ),
      ),
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
  }) {
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
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
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: rs.titleFont,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          content,
        ],
      ),
    );
  }

  Widget _buildBulletPoint(
    String text,
    ResponsiveSize rs,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: rs.bodyFont,
                height: 1.5,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
