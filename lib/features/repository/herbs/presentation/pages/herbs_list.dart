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

import 'package:zim_herbs_repo/core/theme/spacing.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';

import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/components/batch_action_toolbar.dart';
import 'package:zim_herbs_repo/features/admin/herb_management/presentation/add_edit_herb_page.dart';
import 'package:zim_herbs_repo/features/admin/moderation/presentation/screens/unverified_herbs_screen.dart';

class HerbsList extends StatefulWidget {
  final VoidCallback? onBack;
  const HerbsList({super.key, this.onBack});

  @override
  State<HerbsList> createState() => _HerbsListState();
}

class _HerbsListState extends State<HerbsList> {
  bool _isSelectionMode = false;
  final Set<String> _selectedHerbIds = {};

  @override
  void initState() {
    super.initState();
  }

  void _enterSelectionMode([Herb? initialHerb]) {
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    return Builder(
      builder: (context) {
        // Load herbs when the Cubit is still in its initial state.
        final currentCubitState =
            context.watch<HerbCubit>().state;

        if (currentCubitState is HerbInitial) {
          context.read<HerbCubit>().loadHerbs();
        }

        final currentHerbs = currentCubitState is HerbLoaded
            ? currentCubitState.herbs
            : <Herb>[];

        return BlocListener<HerbCubit, HerbState>(
          listener: (context, state) {
            // Successful operation
            if (state is HerbOperationSuccess) {
              _selectedHerbIds.clear();
              _isSelectionMode = false;
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
                  : AppBar(
                      toolbarHeight: 10,
                      elevation: 0,
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                    ),

              // ==================================================
              // ADD HERB BUTTON
              // ==================================================

              floatingActionButton: _isSelectionMode
                  ? null
                  : FloatingActionButton(
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
                    ),

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
                      // ACTION TOOLBAR / MARK TOGGLE (RIGHT ABOVE LIST)
                      // ==========================================
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
                            // No herbs
                            if (state.herbs.isEmpty) {
                              return _buildEmptyView(
                                state.searchQuery,
                              );
                            }

                            // =================================
                            // MOBILE
                            // =================================

                            if (Responsive.isMobile(context)) {
                              return MobileHerbList(
                                filteredHerbs: state.herbs,
                                rs: rs,
                                isSelectionMode: _isSelectionMode,
                                selectedHerbIds: _selectedHerbIds,
                                onToggleSelect: _toggleHerbSelection,
                                onLongPress: (herb) =>
                                    _enterSelectionMode(herb),
                                onVerify: (herb) => _handleVerify(context, herb),

                                // Herb entity → HerbModel
                                // because AddEditHerbPage
                                // expects HerbModel.
                                onEdit: (herb) {
                                  _showAddEditDialog(
                                    context,
                                    herb:
                                        HerbModel.fromEntity(
                                      herb,
                                    ),
                                  );
                                },

                                // Delete uses the domain
                                // entity directly.
                                onDelete: (herb) {
                                  _handleDelete(
                                    context,
                                    herb,
                                  );
                                },
                              );
                            }

                            // =================================
                            // DESKTOP / TABLET
                            // =================================

                            return DesktopHerbList(
                              filteredHerbs: state.herbs,
                              rs: rs,
                              isSelectionMode: _isSelectionMode,
                              selectedHerbIds: _selectedHerbIds,
                              onToggleSelect: _toggleHerbSelection,
                              onLongPress: (herb) =>
                                  _enterSelectionMode(herb),
                              onVerify: (herb) => _handleVerify(context, herb),

                              // Herb entity → HerbModel
                              // for AddEditHerbPage.
                              onEdit: (herb) {
                                _showAddEditDialog(
                                  context,
                                  herb:
                                      HerbModel.fromEntity(
                                    herb,
                                  ),
                                );
                              },

                              // Delete uses Herb entity.
                              onDelete: (herb) {
                                _handleDelete(
                                  context,
                                  herb,
                                );
                              },
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
    final theme = Theme.of(context);
    final canGoBack = widget.onBack != null || Navigator.canPop(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: defaultPadding * 0.75,
      ),
      color: theme.scaffoldBackgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Modern back button (when applicable)
          if (canGoBack) ...[
            InkWell(
              onTap: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Title & Subtitle block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "All Herbs",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    fontSize: rs.titleFont * 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  "Botanical catalog & repository",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Unverified shortcut chip
          OutlinedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const UnverifiedHerbsScreen(),
                ),
              );
              if (context.mounted) {
                context.read<HerbCubit>().loadHerbs();
              }
            },
            icon: Icon(
              Icons.verified_user_outlined,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              'Unverified',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
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
        final count =
            state is HerbLoaded ? state.herbs.length : currentHerbs.length;

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
  // EMPTY VIEW
  // ============================================================

  Widget _buildEmptyView(
    String query,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            query.isEmpty
                ? 'No herbs available'
                : 'No herbs found for "$query"',

            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}