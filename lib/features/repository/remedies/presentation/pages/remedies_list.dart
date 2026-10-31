import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/components/app_filter_bar.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/components/batch_action_toolbar.dart';
import 'package:zim_herbs_repo/core/components/rejection_reason_dialog.dart';
import 'package:zim_herbs_repo/core/components/searchable_dropdown.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/admin/remedy_management/presentation/add_edit_remedy_page.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/datasources/condition_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/models/condition_model.dart';
import 'package:zim_herbs_repo/features/repository/remedies/data/datasources/remedy_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/remedies/data/repositories/remedy_repository_impl.dart';
import 'package:zim_herbs_repo/features/repository/remedies/domain/entities/remedy.dart';
import 'package:zim_herbs_repo/features/repository/remedies/domain/repositories/remedy_repository.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/components/desktop_remedy_list.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/components/mobile_remedy_list.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/cubit/remedy_cubit.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/cubit/remedy_state.dart';

enum RemedyFilterOption {
  all,
  published,
  pendingReview,
  myCreations,
}

class RemediesList extends StatelessWidget {
  final String? initialConditionId;
  final VoidCallback? onBack;
  final RemedyRepository? repository;
  final ConditionRemoteDataSource? conditionDataSource;
  final bool isPublicView;

  const RemediesList({
    super.key,
    this.initialConditionId,
    this.onBack,
    this.repository,
    this.conditionDataSource,
    this.isPublicView = false,
  });

  @override
  Widget build(BuildContext context) {
    final remedyRepository =
        repository ??
        RemedyRepositoryImpl(
          RemedyRemoteDataSource(Supabase.instance.client),
        );

    return BlocProvider(
      create: (context) {
        final cubit = RemedyCubit(remedyRepository);
        if (initialConditionId != null) {
          cubit.filterByCondition(initialConditionId);
        } else {
          cubit.loadRemedies();
        }
        return cubit;
      },
      child: _RemediesListView(
        initialConditionId: initialConditionId,
        onBack: onBack,
        conditionDataSource: conditionDataSource,
        isPublicView: isPublicView,
      ),
    );
  }
}

class _RemediesListView extends StatefulWidget {
  final String? initialConditionId;
  final VoidCallback? onBack;
  final ConditionRemoteDataSource? conditionDataSource;
  final bool isPublicView;

  const _RemediesListView({
    this.initialConditionId,
    this.onBack,
    this.conditionDataSource,
    this.isPublicView = false,
  });

  @override
  State<_RemediesListView> createState() => _RemediesListViewState();
}

class _RemediesListViewState extends State<_RemediesListView> {
  bool _isSelectionMode = false;
  final Set<String> _selectedRemedyIds = {};
  RemedyFilterOption _currentFilter = RemedyFilterOption.all;
  late final Future<List<ConditionModel>> _conditionsFuture;

  @override
  void initState() {
    super.initState();
    _conditionsFuture = widget.conditionDataSource != null
        ? widget.conditionDataSource!.getAllConditions()
        : () {
            try {
              return ConditionRemoteDataSource(Supabase.instance.client)
                  .getAllConditions();
            } catch (_) {
              return Future.value(<ConditionModel>[]);
            }
          }();
  }

  AuthState? _getAuthState(BuildContext context) {
    try {
      return context.watch<AuthCubit>().state;
    } catch (_) {
      return null;
    }
  }

  AuthState? _readAuthState(BuildContext context) {
    try {
      return context.read<AuthCubit>().state;
    } catch (_) {
      return null;
    }
  }

  void _enterSelectionMode([Remedy? initialRemedy]) {
    final authState = _readAuthState(context);
    final canManage = authState is Authenticated && authState.user.canModerate;
    if (!canManage) return;

    setState(() {
      _isSelectionMode = true;
      if (initialRemedy != null) {
        _selectedRemedyIds.add(initialRemedy.id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedRemedyIds.clear();
    });
  }

  void _toggleRemedySelection(Remedy remedy) {
    setState(() {
      if (_selectedRemedyIds.contains(remedy.id)) {
        _selectedRemedyIds.remove(remedy.id);
      } else {
        _selectedRemedyIds.add(remedy.id);
      }
    });
  }

  void _toggleSelectAll(List<Remedy> currentRemedies) {
    setState(() {
      final allVisibleIds = currentRemedies.map((r) => r.id).toSet();
      final isAllSelected = allVisibleIds.isNotEmpty &&
          allVisibleIds.every((id) => _selectedRemedyIds.contains(id));

      if (isAllSelected) {
        _selectedRemedyIds.removeAll(allVisibleIds);
      } else {
        _selectedRemedyIds.addAll(allVisibleIds);
      }
    });
  }

  Future<void> _handleVerify(BuildContext context, Remedy remedy) async {
    try {
      final authState = _readAuthState(context);
      final currentUserId =
          authState is Authenticated ? authState.user.id : null;
      await context.read<RemedyCubit>().approveRemedy(
            remedy.id,
            approved: !remedy.isApproved,
            verifiedBy: currentUserId,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update ${remedy.name}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, Remedy remedy) async {
    final reason = await RejectionReasonDialog.show(
      context,
      recordName: remedy.name,
      recordType: 'Remedy',
    );

    if (reason != null && reason.trim().isNotEmpty && context.mounted) {
      final authState = _readAuthState(context);
      final currentUserId =
          authState is Authenticated ? authState.user.id : null;
      await context.read<RemedyCubit>().approveRemedy(
            remedy.id,
            approved: false,
            verifiedBy: currentUserId,
            moderationNotes: reason.trim(),
          );
    }
  }

  Future<void> _handleDelete(BuildContext context, Remedy remedy) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Remedy'),
        content: Text('Are you sure you want to delete "${remedy.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<RemedyCubit>().deleteRemedy(remedy.id);
    }
  }

  Future<void> _handleDeleteSelected(BuildContext context) async {
    final count = _selectedRemedyIds.length;
    if (count == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $count ${count > 1 ? 'Remedies' : 'Remedy'}'),
        content: Text(
          'Are you sure you want to delete $count marked ${count > 1 ? 'remedies' : 'remedy'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final idsToDelete = _selectedRemedyIds.toList();
      _exitSelectionMode();
      context.read<RemedyCubit>().deleteRemedies(idsToDelete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final authState = _getAuthState(context);
    final currentUserId = authState is Authenticated ? authState.user.id : null;
    final canManage = !widget.isPublicView &&
        authState is Authenticated &&
        authState.user.canModerate;

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        appBar: Responsive.isDesktop(context)
            ? null
            : AppPageAppBar(
                title: widget.isPublicView ? 'Remedies Catalog' : 'Remedies',
                onBack: widget.onBack,
              ),
        floatingActionButton: (!widget.isPublicView &&
                !_isSelectionMode &&
                authState is Authenticated)
            ? FloatingActionButton(
                tooltip: canManage ? 'Add Remedy' : 'Contribute Remedy',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditRemedyPage(),
                    ),
                  );
                  if (!context.mounted) return;
                  if (result == true) {
                    context.read<RemedyCubit>().refreshRemedies();
                  }
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 4,
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: BlocListener<RemedyCubit, RemedyState>(
              listener: (context, state) {
                if (state is RemedyOperationSuccess) {
                  setState(() {
                    _selectedRemedyIds.clear();
                    _isSelectionMode = false;
                  });
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              child: BlocBuilder<RemedyCubit, RemedyState>(
                builder: (context, state) {
                  final rawRemedies =
                      state is RemedyLoaded ? state.remedies : <Remedy>[];

                  // Step 1: Baseline visibility (Learner vs Staff boundary)
                  final visibleRemedies = rawRemedies.where((remedy) {
                    if (canManage) return true;
                    if (remedy.isApproved || remedy.validationStatus.isApproved) {
                      return true;
                    }
                    if (!widget.isPublicView &&
                        currentUserId != null &&
                        remedy.createdBy != null &&
                        remedy.createdBy == currentUserId) {
                      return true;
                    }
                    return false;
                  }).toList();

                  // Step 2: Tab / Chip filter selection
                  final currentRemedies = visibleRemedies.where((remedy) {
                    final isAuthor = currentUserId != null &&
                        remedy.createdBy != null &&
                        remedy.createdBy == currentUserId;
                    final isApproved =
                        remedy.isApproved || remedy.validationStatus.isApproved;

                    switch (_currentFilter) {
                      case RemedyFilterOption.all:
                        return true;
                      case RemedyFilterOption.published:
                        return canManage
                            ? isApproved
                            : (isAuthor && isApproved);
                      case RemedyFilterOption.pendingReview:
                        return canManage
                            ? !isApproved
                            : (isAuthor && !isApproved);
                      case RemedyFilterOption.myCreations:
                        return isAuthor;
                    }
                  }).toList();

                  final allCount = visibleRemedies.length;
                  final publishedCount = canManage
                      ? visibleRemedies
                          .where((r) =>
                              r.isApproved || r.validationStatus.isApproved)
                          .length
                      : (currentUserId != null
                          ? visibleRemedies
                              .where((r) =>
                                  r.createdBy != null &&
                                  r.createdBy == currentUserId &&
                                  (r.isApproved ||
                                      r.validationStatus.isApproved))
                              .length
                          : 0);

                  final pendingCount = canManage
                      ? visibleRemedies
                          .where((r) =>
                              !r.isApproved && !r.validationStatus.isApproved)
                          .length
                      : (currentUserId != null
                          ? visibleRemedies
                              .where((r) =>
                                  r.createdBy != null &&
                                  r.createdBy == currentUserId &&
                                  (!r.isApproved &&
                                      !r.validationStatus.isApproved))
                              .length
                          : 0);

                  final myCreationsCount = currentUserId != null
                      ? visibleRemedies
                          .where((r) =>
                              r.createdBy != null &&
                              r.createdBy == currentUserId)
                          .length
                      : 0;

                  return Column(
                    children: [
                      // Header
                      _buildHeader(context, rs),

                      // Search & Condition Filter
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: rs.defaultPadding,
                          vertical: 6.0,
                        ),
                        child: Column(
                          children: [
                            // Search field
                            TextField(
                              onChanged: (value) => context
                                  .read<RemedyCubit>()
                                  .searchRemedies(value),
                              decoration: InputDecoration(
                                hintText:
                                    'Search remedies by name or condition...',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Condition dropdown filter
                            FutureBuilder<List<ConditionModel>>(
                              future: _conditionsFuture,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox.shrink();
                                }
                                ConditionModel? initialSelected;
                                if (widget.initialConditionId != null) {
                                  try {
                                    initialSelected = snapshot.data!.firstWhere(
                                      (c) =>
                                          c.id == widget.initialConditionId,
                                    );
                                  } catch (_) {}
                                }

                                return _ConditionFilterDropdown(
                                  conditions: snapshot.data!,
                                  initialValue: initialSelected,
                                  rs: rs,
                                  onConditionSelected: (selected) {
                                    context
                                        .read<RemedyCubit>()
                                        .filterByCondition(selected?.id);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Filter Bar (All / Published / Pending Review / My Creations)
                      if (!widget.isPublicView)
                        _buildFilterBar(
                          context,
                          allCount: allCount,
                          publishedCount: publishedCount,
                          pendingCount: pendingCount,
                          myCreationsCount: myCreationsCount,
                          canManage: canManage,
                          hasUser: currentUserId != null,
                        ),

                      // Action Toolbar / Mark Toggle
                      if (canManage)
                        _buildActionToolbar(context, rs, currentRemedies),

                      // Content
                      Expanded(
                        child: () {
                          if (state is RemedyLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (state is RemedyError) {
                            return AppErrorView(
                              failure: state.failure,
                              message: state.message,
                              onRetry: () =>
                                  context.read<RemedyCubit>().refreshRemedies(),
                            );
                          }

                          if (currentRemedies.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.task_alt_rounded,
                                    size: 48,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    state is RemedyLoaded &&
                                            state.searchQuery.isNotEmpty
                                        ? 'No remedies matching "${state.searchQuery}"'
                                        : (_currentFilter ==
                                                RemedyFilterOption.pendingReview
                                            ? 'All remedies have been reviewed!'
                                            : 'No remedies found matching criteria.'),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () =>
                                context.read<RemedyCubit>().refreshRemedies(),
                            child: Responsive.isMobile(context)
                                ? MobileRemedyList(
                                    remedies: currentRemedies,
                                    rs: rs,
                                    isPublicView: widget.isPublicView,
                                    isSelectionMode:
                                        canManage && _isSelectionMode,
                                    selectedRemedyIds: canManage
                                        ? _selectedRemedyIds
                                        : const {},
                                    onToggleSelect: canManage
                                        ? _toggleRemedySelection
                                        : null,
                                    onLongPress: canManage
                                        ? (remedy) =>
                                            _enterSelectionMode(remedy)
                                        : null,
                                    onToggleApproval: canManage
                                        ? (remedy) =>
                                            _handleVerify(context, remedy)
                                        : null,
                                    onReject: canManage
                                        ? (remedy) =>
                                            _handleReject(context, remedy)
                                        : null,
                                    onDelete: canManage
                                        ? (remedy) =>
                                            _handleDelete(context, remedy)
                                        : null,
                                    showStatusChip: canManage,
                                    currentUserId: currentUserId,
                                  )
                                : DesktopRemedyList(
                                    remedies: currentRemedies,
                                    rs: rs,
                                    isPublicView: widget.isPublicView,
                                    isSelectionMode:
                                        canManage && _isSelectionMode,
                                    selectedRemedyIds: canManage
                                        ? _selectedRemedyIds
                                        : const {},
                                    onToggleSelect: canManage
                                        ? _toggleRemedySelection
                                        : null,
                                    onLongPress: canManage
                                        ? (remedy) =>
                                            _enterSelectionMode(remedy)
                                        : null,
                                    onToggleApproval: canManage
                                        ? (remedy) =>
                                            _handleVerify(context, remedy)
                                        : null,
                                    onReject: canManage
                                        ? (remedy) =>
                                            _handleReject(context, remedy)
                                        : null,
                                    onDelete: canManage
                                        ? (remedy) =>
                                            _handleDelete(context, remedy)
                                        : null,
                                    showStatusChip: canManage,
                                    currentUserId: currentUserId,
                                  ),
                          );
                        }(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context, {
    required int allCount,
    required int publishedCount,
    required int pendingCount,
    required int myCreationsCount,
    required bool canManage,
    required bool hasUser,
  }) {
    final options = <FilterOption<RemedyFilterOption>>[
      FilterOption(
        label: 'All',
        value: RemedyFilterOption.all,
        count: allCount,
      ),
      if (hasUser && !canManage)
        FilterOption(
          label: 'My Creations',
          value: RemedyFilterOption.myCreations,
          count: myCreationsCount,
          activeColor: Colors.teal.shade700,
        ),
      if (canManage || hasUser) ...[
        FilterOption(
          label: 'Published',
          value: RemedyFilterOption.published,
          count: publishedCount,
          activeColor: Colors.green.shade700,
        ),
        FilterOption(
          label: 'Pending Review',
          value: RemedyFilterOption.pendingReview,
          count: pendingCount,
          activeColor: Colors.amber.shade800,
        ),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 12.0, bottom: 6.0),
      child: AppFilterBar<RemedyFilterOption>(
        options: options,
        selectedValue: _currentFilter,
        onSelected: (selected) {
          setState(() {
            _currentFilter = selected;
          });
        },
      ),
    );
  }

  Widget _buildActionToolbar(
    BuildContext context,
    ResponsiveSize rs,
    List<Remedy> currentRemedies,
  ) {
    final allVisibleIds = currentRemedies.map((r) => r.id).toSet();
    final isAllSelected = allVisibleIds.isNotEmpty &&
        allVisibleIds.every((id) => _selectedRemedyIds.contains(id));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: rs.defaultPadding),
      child: BatchActionToolbar(
        isSelectionMode: _isSelectionMode,
        totalCount: currentRemedies.length,
        itemLabel: 'remedies',
        selectedCount: _selectedRemedyIds.length,
        isAllSelected: isAllSelected,
        onEnterSelectionMode: _enterSelectionMode,
        onCancelSelection: _exitSelectionMode,
        onToggleSelectAll: currentRemedies.isNotEmpty
            ? () => _toggleSelectAll(currentRemedies)
            : null,
        onDeleteSelected: () => _handleDeleteSelected(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ResponsiveSize rs) {
    return AppPageHeader(
      title: widget.isPublicView ? "Remedies Catalog" : "All Remedies",
      subtitle: widget.isPublicView
          ? "Holistic botanical formulas & preparations"
          : "Traditional remedies & formulations",
      icon: Icons.healing_rounded,
      onBack: widget.onBack,
    );
  }
}

class _ConditionFilterDropdown extends StatefulWidget {
  final List<ConditionModel> conditions;
  final ConditionModel? initialValue;
  final ValueChanged<ConditionModel?> onConditionSelected;
  final ResponsiveSize rs;

  const _ConditionFilterDropdown({
    required this.conditions,
    this.initialValue,
    required this.onConditionSelected,
    required this.rs,
  });

  @override
  State<_ConditionFilterDropdown> createState() =>
      _ConditionFilterDropdownState();
}

class _ConditionFilterDropdownState extends State<_ConditionFilterDropdown> {
  ConditionModel? _selectedCondition;

  @override
  void initState() {
    super.initState();
    _selectedCondition = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return SearchableDropdown<ConditionModel>(
      items: widget.conditions,
      value: _selectedCondition,
      label: 'Filter by Condition',
      itemLabelBuilder: (c) => c.name,
      rs: widget.rs,
      onChanged: (selected) {
        setState(() => _selectedCondition = selected);
        widget.onConditionSelected(selected);
      },
    );
  }
}
