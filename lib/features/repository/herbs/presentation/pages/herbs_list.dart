import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zim_herbs_repo/features/repository/herbs/data/models/herb_model.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';

import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/cubit/herb_cubit.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/cubit/herb_state.dart';

import 'package:zim_herbs_repo/features/repository/herbs/presentation/components/desktop_herb_list.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/components/mobile_herb_list.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/pages/herb_details.dart';

import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';

import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/components/app_filter_bar.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/components/batch_action_toolbar.dart';
import 'package:zim_herbs_repo/features/admin/herb_management/presentation/add_edit_herb_page.dart';

enum HerbFilterOption {
  all,
  published,
  pendingReview,
  myCreations,
}

class HerbsList extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isPublicView;

  const HerbsList({
    super.key,
    this.onBack,
    this.isPublicView = false,
  });

  @override
  State<HerbsList> createState() => _HerbsListState();
}

class _HerbsListState extends State<HerbsList> {
  bool _isSelectionMode = false;
  final Set<String> _selectedHerbIds = {};
  HerbFilterOption _currentFilter = HerbFilterOption.all;

  @override
  void initState() {
    super.initState();
  }

  void _enterSelectionMode([Herb? initialHerb]) {
    if (widget.isPublicView) return;
    // Called from event handlers (tap / long press), so we must use a
    // non-listening read. `context.watch` is only legal inside build().
    final authState = _readAuthState(context);
    final canManage = authState is Authenticated && authState.user.canModerate;
    if (!canManage) return;

    setState(() {
      _isSelectionMode = true;
      if (initialHerb != null) {
        _selectedHerbIds.add(initialHerb.id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedHerbIds.clear();
    });
  }

  void _toggleHerbSelection(Herb herb) {
    setState(() {
      if (_selectedHerbIds.contains(herb.id)) {
        _selectedHerbIds.remove(herb.id);
      } else {
        _selectedHerbIds.add(herb.id);
      }
    });
  }

  void _toggleSelectAll(List<Herb> currentHerbs) {
    setState(() {
      final allVisibleIds = currentHerbs.map((h) => h.id).toSet();
      final isAllSelected = allVisibleIds.isNotEmpty &&
          allVisibleIds.every((id) => _selectedHerbIds.contains(id));

      if (isAllSelected) {
        _selectedHerbIds.removeAll(allVisibleIds);
      } else {
        _selectedHerbIds.addAll(allVisibleIds);
      }
    });
  }

  // ============================================================
  // DELETE HERB
  // ============================================================

  Future<void> _handleDelete(
    BuildContext context,
    Herb herb,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Herb'),
        content: Text(
          'Are you sure you want to delete "${herb.nameEn}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<HerbCubit>().deleteHerb(herb.id);
    }
  }

  // ============================================================
  // DELETE MARKED HERBS
  // ============================================================

  Future<void> _handleDeleteSelected(BuildContext context) async {
    final count = _selectedHerbIds.length;
    if (count == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $count Herb${count > 1 ? 's' : ''}'),
        content: Text(
          'Are you sure you want to delete $count marked herb${count > 1 ? 's' : ''}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final idsToDelete = _selectedHerbIds.toList();
      _exitSelectionMode();
      context.read<HerbCubit>().deleteHerbs(idsToDelete);
    }
  }

  // ============================================================
  // VERIFY HERB
  // ============================================================

  Future<void> _handleVerify(BuildContext context, Herb herb) async {
    try {
      final authState = context.read<AuthCubit>().state;
      final currentUserId =
          authState is Authenticated ? authState.user.id : null;
      await context.read<HerbCubit>().updateHerbVerification(
            herb.id,
            true,
            verifiedBy: currentUserId,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${herb.nameEn} verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify ${herb.nameEn}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // ADD / EDIT HERB
  // ============================================================

  Future<void> _showAddEditDialog(
    BuildContext context, {
    HerbModel? herb,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditHerbPage(
          herb: herb,
        ),
      ),
    );

    if (result == true) {
      if (mounted && context.mounted) {
        context.read<HerbCubit>().refreshHerbs();
      }
    }
  }

  // ============================================================
  // OPEN FULL HERB DETAILS (Edits happen on detail page)
  // ============================================================

  Future<void> _openHerbDetails(BuildContext context, Herb herb) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HerbDetailsPage(herbId: herb.id),
      ),
    );

    if (mounted && context.mounted) {
      context.read<HerbCubit>().refreshHerbs();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  AuthState? _getAuthState(BuildContext context) {
    try {
      return context.watch<AuthCubit>().state;
    } catch (_) {
      return null;
    }
  }

  /// Non-listening variant for use inside callbacks (outside build).
  AuthState? _readAuthState(BuildContext context) {
    try {
      return context.read<AuthCubit>().state;
    } catch (_) {
      return null;
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

    return Builder(
      builder: (context) {
        // Load herbs when the Cubit is still in its initial state.
        final currentCubitState =
            context.watch<HerbCubit>().state;

        if (currentCubitState is HerbInitial) {
          context.read<HerbCubit>().loadHerbs();
        }

        final rawHerbs = currentCubitState is HerbLoaded
            ? currentCubitState.herbs
            : <Herb>[];

        // Step 1: Baseline visibility (Learner vs Staff boundary)
        // Public/Learner sees published herbs + their own creations (even when pending).
        // Staff/Moderators see all herbs across the system.
        final visibleHerbs = rawHerbs.where((herb) {
          if (canManage) return true;
          if (herb.isApproved || herb.validationStatus.isApproved) return true;
          if (!widget.isPublicView &&
              currentUserId != null &&
              herb.createdBy != null &&
              herb.createdBy == currentUserId) {
            return true;
          }
          return false;
        }).toList();

        // Step 2: Tab / Chip filter selection
        final currentHerbs = visibleHerbs.where((herb) {
          final isAuthor = currentUserId != null &&
              herb.createdBy != null &&
              herb.createdBy == currentUserId;
          final isApproved = herb.isApproved || herb.validationStatus.isApproved;

          switch (_currentFilter) {
            case HerbFilterOption.all:
              return true;
            case HerbFilterOption.published:
              return canManage ? isApproved : (isAuthor && isApproved);
            case HerbFilterOption.pendingReview:
              return canManage ? !isApproved : (isAuthor && !isApproved);
            case HerbFilterOption.myCreations:
              return isAuthor;
          }
        }).toList();

        final allCount = visibleHerbs.length;
        final publishedCount = canManage
            ? visibleHerbs
                .where((h) => h.isApproved || h.validationStatus.isApproved)
                .length
            : (currentUserId != null
                ? visibleHerbs
                    .where((h) =>
                        h.createdBy != null &&
                        h.createdBy == currentUserId &&
                        (h.isApproved || h.validationStatus.isApproved))
                    .length
                : 0);

        final pendingCount = canManage
            ? visibleHerbs
                .where((h) => !h.isApproved && !h.validationStatus.isApproved)
                .length
            : (currentUserId != null
                ? visibleHerbs
                    .where((h) =>
                        h.createdBy != null &&
                        h.createdBy == currentUserId &&
                        (!h.isApproved && !h.validationStatus.isApproved))
                    .length
                : 0);

        final myCreationsCount = currentUserId != null
            ? visibleHerbs
                .where((h) => h.createdBy != null && h.createdBy == currentUserId)
                .length
            : 0;

        return BlocListener<HerbCubit, HerbState>(
          listener: (context, state) {
            // Successful operation
            if (state is HerbOperationSuccess) {
              setState(() {
                _selectedHerbIds.clear();
                _isSelectionMode = false;
              });
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                ),
              );
            }
          },

          child: PopScope(
            canPop: !_isSelectionMode,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (_isSelectionMode) {
                _exitSelectionMode();
              }
            },
            child: Scaffold(
              // ==================================================
              // APP BAR
              // ==================================================

              appBar: Responsive.isDesktop(context)
                  ? null
                  : AppPageAppBar(
                      title: widget.isPublicView ? 'Herbal Catalog' : 'Herbs',
                      onBack: widget.onBack,
                    ),

              // ==================================================
              // ADD / CONTRIBUTE HERB BUTTON
              // ==================================================

              floatingActionButton: (!_isSelectionMode && canManage)
                  ? FloatingActionButton(
                      tooltip: 'Add Herb',

                      onPressed: () {
                        _showAddEditDialog(context);
                      },

                      backgroundColor:
                          Theme.of(context).colorScheme.primary,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color:
                              Theme.of(context).colorScheme.secondary,
                          width: 4,
                        ),
                      ),

                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                    )
                  : null,

              // ==================================================
              // BODY
              // ==================================================

              body: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .scaffoldBackgroundColor,
                  ),

                  child: Column(
                    children: [
                      // ==========================================
                      // HEADER (NAVBAR)
                      // ==========================================
                      _buildHeader(context, rs, currentHerbs),

                      // ==========================================
                      // SEARCH BAR
                      // ==========================================
                      _buildSearchBar(context),

                      // ==========================================
                      // FILTER TABS (All / Published / My Creations)
                      // ==========================================
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

                      // ==========================================
                      // ACTION TOOLBAR / MARK TOGGLE (RIGHT ABOVE LIST)
                      // (Only displayed for staff/admin with management rights)
                      // ==========================================
                      if (canManage)
                        _buildActionToolbar(context, rs, currentHerbs),

                      // ==========================================
                      // HERB LIST
                      // ==========================================

                    Expanded(
                      child:
                          BlocBuilder<HerbCubit, HerbState>(
                        builder: (context, state) {
                          // ====================================
                          // LOADING
                          // ====================================

                          if (state is HerbLoading ||
                              state is HerbInitial) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(),
                            );
                          }

                          // ====================================
                          // ERROR
                          // ====================================

                          if (state is HerbError) {
                            return AppErrorView(
                              failure: state.failure,
                              message: state.message,
                              onRetry: () =>
                                  context.read<HerbCubit>().loadHerbs(),
                            );
                          }

                          // ====================================
                          // LOADED
                          // ====================================

                          if (state is HerbLoaded) {
                            // No herbs matching
                            if (currentHerbs.isEmpty) {
                              return _buildEmptyView(
                                state.searchQuery,
                                canManage: canManage,
                              );
                            }

                            // =================================
                            // MOBILE
                            // =================================

                            if (Responsive.isMobile(context)) {
                              return MobileHerbList(
                                filteredHerbs: currentHerbs,
                                rs: rs,
                                isPublicView: widget.isPublicView,
                                isSelectionMode: canManage && _isSelectionMode,
                                selectedHerbIds: canManage ? _selectedHerbIds : const {},
                                onToggleSelect: canManage ? _toggleHerbSelection : null,
                                onLongPress: canManage
                                    ? (herb) => _enterSelectionMode(herb)
                                    : null,
                                onView: (herb) =>
                                    _openHerbDetails(context, herb),
                                showStatusChip: canManage,
                                currentUserId: currentUserId,
                              );
                            }

                            // =================================
                            // DESKTOP / TABLET
                            // =================================

                            return DesktopHerbList(
                              filteredHerbs: currentHerbs,
                              rs: rs,
                              isPublicView: widget.isPublicView,
                              isSelectionMode: canManage && _isSelectionMode,
                              selectedHerbIds: canManage ? _selectedHerbIds : const {},
                              onToggleSelect: canManage ? _toggleHerbSelection : null,
                              onLongPress: canManage
                                  ? (herb) => _enterSelectionMode(herb)
                                  : null,
                              onTapHerb: (herb) =>
                                  _openHerbDetails(context, herb),
                              onVerify: canManage
                                  ? (herb) => _handleVerify(context, herb)
                                  : null,
                              onDelete: canManage
                                  ? (herb) => _handleDelete(context, herb)
                                  : null,
                              showStatusChip: canManage,
                              currentUserId: currentUserId,
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
    ResponsiveSize rs,
    List<Herb> currentHerbs,
  ) {
    return AppPageHeader(
      title: widget.isPublicView ? "Herbal Catalog" : "All Herbs",
      subtitle: widget.isPublicView
          ? "Indigenous Zimbabwean medicinal flora"
          : "Botanical catalog & repository",
      icon: Icons.local_florist_rounded,
      onBack: widget.onBack,
    );
  }

  // ============================================================
  // ACTION TOOLBAR / MARK TOGGLE (RIGHT ABOVE LIST)
  // ============================================================

  Widget _buildActionToolbar(
    BuildContext context,
    ResponsiveSize rs,
    List<Herb> currentHerbs,
  ) {
    final allVisibleIds = currentHerbs.map((h) => h.id).toSet();
    final isAllSelected = allVisibleIds.isNotEmpty &&
        allVisibleIds.every((id) => _selectedHerbIds.contains(id));

    return BlocBuilder<HerbCubit, HerbState>(
      builder: (context, state) {
        // Count reflects the currently filtered list (All / Published / Pending).
        final count = currentHerbs.length;

        return BatchActionToolbar(
          isSelectionMode: _isSelectionMode,
          totalCount: count,
          itemLabel: 'herbs',
          selectedCount: _selectedHerbIds.length,
          isAllSelected: isAllSelected,
          onEnterSelectionMode: _enterSelectionMode,
          onCancelSelection: _exitSelectionMode,
          onToggleSelectAll: currentHerbs.isNotEmpty
              ? () => _toggleSelectAll(currentHerbs)
              : null,
          onDeleteSelected: () => _handleDeleteSelected(context),
        );
      },
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12.0),

      child: TextField(
        onChanged: (value) {
          context
              .read<HerbCubit>()
              .searchHerbs(value);
        },

        decoration: InputDecoration(
          hintText: "Search herbs...",

          filled: true,

          fillColor:
              Theme.of(context).colorScheme.onPrimary,

          prefixIcon: Icon(
            Icons.search,

            color:
                Theme.of(context).colorScheme.primary,
          ),

          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),

            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar(
    BuildContext context, {
    required int allCount,
    required int publishedCount,
    required int pendingCount,
    required int myCreationsCount,
    required bool canManage,
    required bool hasUser,
  }) {
    final options = <FilterOption<HerbFilterOption>>[
      FilterOption(
        label: 'All',
        value: HerbFilterOption.all,
        count: allCount,
      ),
      if (hasUser && !canManage)
        FilterOption(
          label: 'My Creations',
          value: HerbFilterOption.myCreations,
          count: myCreationsCount,
          activeColor: Colors.teal.shade700,
        ),
      if (canManage || hasUser) ...[
        FilterOption(
          label: 'Published',
          value: HerbFilterOption.published,
          count: publishedCount,
          activeColor: Colors.green.shade700,
        ),
        FilterOption(
          label: 'Pending Review',
          value: HerbFilterOption.pendingReview,
          count: pendingCount,
          activeColor: Colors.amber.shade800,
        ),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
      child: AppFilterBar<HerbFilterOption>(
        options: options,
        selectedValue: _currentFilter,
        onSelected: (val) {
          setState(() {
            _currentFilter = val;
            // Prevent hidden (filtered-out) herbs from staying marked and
            // being deleted unintentionally.
            _selectedHerbIds.clear();
          });
        },
      ),
    );
  }

  // ============================================================
  // EMPTY VIEW
  // ============================================================

  Widget _buildEmptyView(
    String query, {
    bool canManage = false,
  }) {
    String emptyMessage;
    IconData emptyIcon = Icons.search_off;

    if (query.isNotEmpty) {
      emptyMessage = 'No herbs found for "$query"';
    } else if (_currentFilter == HerbFilterOption.myCreations) {
      emptyMessage =
          'You have not submitted any herbs yet.\nVisit Contributions to submit your first herb!';
      emptyIcon = Icons.eco_outlined;
    } else if (_currentFilter == HerbFilterOption.pendingReview) {
      emptyMessage = canManage
          ? 'No herbs currently pending review.'
          : 'You have no herbs currently pending review.';
      emptyIcon = Icons.verified_user_outlined;
    } else if (_currentFilter == HerbFilterOption.published && !canManage) {
      emptyMessage =
          'You have no published herbs yet.\nOnce reviewed and approved, your creations will appear here.';
      emptyIcon = Icons.check_circle_outline;
    } else {
      emptyMessage = 'No herbs available';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}