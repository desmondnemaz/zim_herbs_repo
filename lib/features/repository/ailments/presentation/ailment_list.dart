import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/repository/ailments/domain/entities/ailment.dart';
import 'package:zim_herbs_repo/features/repository/ailments/presentation/cubit/ailment_cubit.dart';
import 'package:zim_herbs_repo/features/repository/ailments/presentation/cubit/ailment_state.dart';
import 'package:zim_herbs_repo/features/admin/ailment_management/presentation/components/add_edit_ailment_dialog.dart';
import 'package:zim_herbs_repo/features/repository/ailments/data/models/ailment_model.dart';
import 'package:zim_herbs_repo/features/repository/ailments/presentation/components/desktop_ailment_list.dart';
import 'package:zim_herbs_repo/features/repository/ailments/presentation/components/mobile_ailment_list.dart';
import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';

class AilmentsListPage extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isPublicView;

  const AilmentsListPage({
    super.key,
    this.onBack,
    this.isPublicView = false,
  });

  @override
  State<AilmentsListPage> createState() => _AilmentsListPageState();
}

/// Backward compatibility typedef
typedef ConditionsListPage = AilmentsListPage;

class _AilmentsListPageState extends State<AilmentsListPage> {
  AilmentCategory? _selectedAilmentCategory;

  Future<void> _handleDelete(BuildContext context, Ailment ailment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Ailment'),
            content: Text(
              'Are you sure you want to delete "${ailment.name}"?',
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
      context.read<AilmentCubit>().deleteAilment(ailment.id);
    }
  }

  Future<void> _showAddEditDialog({
    required BuildContext context,
    Ailment? ailment,
  }) async {
    await showDialog(
      context: context,
      builder:
          (dialogContext) => AddEditAilmentDialog(
            ailment:
                ailment != null ? AilmentModel.fromEntity(ailment) : null,
            onSave: (newAilmentModel) async {
              final newAilment = newAilmentModel.toEntity();
              final bodyPartIds =
                  newAilmentModel.bodyParts.map((bp) => bp.id).toList();
              if (ailment == null) {
                context.read<AilmentCubit>().createAilment(
                  newAilment,
                  bodyPartIds: bodyPartIds,
                );
              } else {
                context.read<AilmentCubit>().updateAilment(
                  newAilment,
                  bodyPartIds: bodyPartIds,
                );
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    AuthState? authState;
    try {
      authState = context.watch<AuthCubit>().state;
    } catch (_) {}
    final canManage =
        !widget.isPublicView &&
        authState is Authenticated &&
        authState.user.canModerate;

    return Builder(
      builder: (context) {
        final currentCubitState = context.read<AilmentCubit>().state;
        if (currentCubitState is AilmentInitial) {
          context.read<AilmentCubit>().loadAilments();
        }

        return BlocListener<AilmentCubit, AilmentState>(
          listener: (context, state) {
            if (state is AilmentOperationSuccess) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          child: Scaffold(
            appBar:
                Responsive.isDesktop(context)
                    ? null
                    : AppPageAppBar(
                        title:
                            widget.isPublicView
                                ? 'Ailments Catalog'
                                : 'Ailments',
                        onBack: widget.onBack,
                      ),
            body: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Column(
                  children: [
                    _buildHeader(context, rs, canManage: canManage),

                    Expanded(
                      child: BlocBuilder<AilmentCubit, AilmentState>(
                        builder: (context, state) {
                          if (state is AilmentLoading ||
                              state is AilmentInitial) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (state is AilmentError) {
                            return AppErrorView(
                              failure: state.failure,
                              message: state.message,
                              onRetry:
                                  () =>
                                      context
                                          .read<AilmentCubit>()
                                          .loadAilments(),
                            );
                          }

                          if (state is AilmentLoaded) {
                            final filteredByCategory =
                                _selectedAilmentCategory == null
                                    ? state.ailments
                                    : state.ailments
                                        .where(
                                          (c) =>
                                              c.ailmentCategory ==
                                              _selectedAilmentCategory,
                                        )
                                        .toList();

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Ailments Found: ${filteredByCategory.length}",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      Text(
                                        "Total: ${state.ailments.length}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildFilters(context, rs, state.searchQuery),
                                Expanded(
                                  child:
                                      filteredByCategory.isEmpty
                                          ? _buildEmptyView(state.searchQuery)
                                          : Responsive(
                                            mobile: MobileAilmentList(
                                              ailments: filteredByCategory,
                                              rs: rs,
                                              isPublicView: widget.isPublicView,
                                              onRefresh: () async {
                                                context
                                                    .read<AilmentCubit>()
                                                    .refreshAilments();
                                              },
                                              onEdit:
                                                  canManage
                                                      ? (cond) =>
                                                          _showAddEditDialog(
                                                            context: context,
                                                            ailment: cond,
                                                          )
                                                      : null,
                                              onDelete:
                                                  canManage
                                                      ? (cond) => _handleDelete(
                                                        context,
                                                        cond,
                                                      )
                                                      : null,
                                            ),
                                            tablet: DesktopAilmentList(
                                              ailments: filteredByCategory,
                                              rs: rs,
                                              isPublicView: widget.isPublicView,
                                              onRefresh: () async {
                                                context
                                                    .read<AilmentCubit>()
                                                    .refreshAilments();
                                              },
                                              onEdit:
                                                  canManage
                                                      ? (cond) =>
                                                          _showAddEditDialog(
                                                            context: context,
                                                            ailment: cond,
                                                          )
                                                      : null,
                                              onDelete:
                                                  canManage
                                                      ? (cond) => _handleDelete(
                                                        context,
                                                        cond,
                                                      )
                                                      : null,
                                            ),
                                            desktop: DesktopAilmentList(
                                              ailments: filteredByCategory,
                                              rs: rs,
                                              isPublicView: widget.isPublicView,
                                              onRefresh: () async {
                                                context
                                                    .read<AilmentCubit>()
                                                    .refreshAilments();
                                              },
                                              onEdit:
                                                  canManage
                                                      ? (cond) =>
                                                          _showAddEditDialog(
                                                            context: context,
                                                            ailment: cond,
                                                          )
                                                      : null,
                                              onDelete:
                                                  canManage
                                                      ? (cond) => _handleDelete(
                                                        context,
                                                        cond,
                                                      )
                                                      : null,
                                            ),
                                          ),
                                ),
                              ],
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
            floatingActionButton:
                canManage
                    ? Builder(
                      builder:
                          (context) => FloatingActionButton(
                            tooltip: 'Add Ailment',
                            onPressed:
                                () => _showAddEditDialog(context: context),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 4,
                              ),
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                    )
                    : null,
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ResponsiveSize rs, {
    required bool canManage,
  }) {
    return AppPageHeader(
      title: widget.isPublicView ? "Ailments Catalog" : "Ailments",
      subtitle:
          widget.isPublicView
              ? "Explore health ailments & targeted remedies"
              : "Medical ailments & targeted remedies",
      icon: Icons.medical_information_rounded,
      onBack: widget.onBack,
    );
  }

  Widget _buildEmptyView(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            query.isEmpty
                ? 'No ailments available'
                : 'No ailments found for "$query"',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, ResponsiveSize rs, String query) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              context.read<AilmentCubit>().searchAilments(value);
            },
            decoration: InputDecoration(
              hintText: 'Search ailments...',
              filled: true,
              fillColor: Theme.of(context).colorScheme.onPrimary,
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AilmentCategory?>(
            initialValue: _selectedAilmentCategory,
            decoration: InputDecoration(
              hintText: 'Filter by ailment category',
              filled: true,
              fillColor: Theme.of(context).colorScheme.onPrimary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            items: [
              const DropdownMenuItem<AilmentCategory?>(
                value: null,
                child: Text('All Categories'),
              ),
              ...AilmentCategory.values.map((category) {
                return DropdownMenuItem<AilmentCategory?>(
                  value: category,
                  child: Text(ailmentCategoryLabel(category)),
                );
              }),
            ],
            onChanged: (category) {
              setState(() {
                _selectedAilmentCategory = category;
              });
              context.read<AilmentCubit>().filterByAilmentCategory(category);
            },
          ),
        ],
      ),
    );
  }
}
