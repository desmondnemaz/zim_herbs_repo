import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zim_herbs_repo/features/repository/herbs/data/models/herb_model.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';

import 'package:zim_herbs_repo/features/repository/herbs/presentation/cubit/herb_cubit.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/cubit/herb_state.dart';

import 'package:zim_herbs_repo/features/repository/herbs/presentation/components/desktop_herb_list.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/components/mobile_herb_list.dart';

import 'package:zim_herbs_repo/core/theme/spacing.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';

import 'package:zim_herbs_repo/features/admin/herb_management/presentation/add_edit_herb_page.dart';

class HerbsList extends StatefulWidget {
  const HerbsList({super.key});

  @override
  State<HerbsList> createState() => _HerbsListState();
}

class _HerbsListState extends State<HerbsList> {
  @override
  void initState() {
    super.initState();
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
            context.read<HerbCubit>().state;

        if (currentCubitState is HerbInitial) {
          context.read<HerbCubit>().loadHerbs();
        }

        return BlocListener<HerbCubit, HerbState>(
          listener: (context, state) {
            // Successful operation
            if (state is HerbOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                ),
              );
            }

            // Error
            else if (state is HerbError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
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

            floatingActionButton: FloatingActionButton(
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
                    // HEADER
                    // ==========================================

                    _buildHeader(context, rs),

                    // ==========================================
                    // HERB COUNTER
                    // ==========================================

                    BlocBuilder<HerbCubit, HerbState>(
                      builder: (context, state) {
                        if (state is HerbLoaded) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: 8,
                              right: 20,
                              bottom: 0,
                            ),

                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.end,

                              children: [
                                Text(
                                  "Total: ${state.herbs.length}",

                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.bold,

                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(
                                          alpha: 0.7,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),

                    // ==========================================
                    // SEARCH BAR
                    // ==========================================

                    _buildSearchBar(context),

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
                            return Center(
                              child: Text(state.message),
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
  ) {
    return Container(
      padding: EdgeInsets.all(defaultPadding),

      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),

      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.pop(context),

            child: Icon(
              Icons.arrow_back,

              color:
                  Theme.of(context).colorScheme.secondary,

              size: rs.appBarIcon,
            ),
          ),

          SizedBox(
            width: defaultPadding,
          ),

          // Title
          Text(
            "All Herbs",

            style: TextStyle(
              fontWeight: FontWeight.bold,

              color:
                  Theme.of(context).colorScheme.secondary,

              fontSize: rs.appBarTitleFont,
            ),
          ),
        ],
      ),
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