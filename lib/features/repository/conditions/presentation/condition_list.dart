import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/entities/condition.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/cubit/condition_cubit.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/cubit/condition_state.dart';
import 'package:zim_herbs_repo/features/admin/condition_management/presentation/components/add_edit_condition_dialog.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/models/condition_model.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/components/desktop_condition_list.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/components/mobile_condition_list.dart';
import 'package:zim_herbs_repo/core/theme/spacing.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';

class ConditionsListPage extends StatefulWidget {
  const ConditionsListPage({super.key});

  @override
  State<ConditionsListPage> createState() => _ConditionsListPageState();
}

class _ConditionsListPageState extends State<ConditionsListPage> {
  BodySystem? _selectedBodySystem;

  Future<void> _handleDelete(
    BuildContext context,
    Condition condition,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Condition'),
            content: Text(
              'Are you sure you want to delete "${condition.name}"?',
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
      context.read<ConditionCubit>().deleteCondition(condition.id);
    }
  }

  Future<void> _showAddEditDialog({
    required BuildContext context,
    Condition? condition,
  }) async {
    await showDialog(
      context: context,
      builder:
          (dialogContext) => AddEditConditionDialog(
            condition: condition != null ? ConditionModel.fromEntity(condition) : null,
            onSave: (newConditionModel) async {
              final newCondition = newConditionModel.toEntity();
              if (condition == null) {
                context.read<ConditionCubit>().createCondition(newCondition);
              } else {
                context.read<ConditionCubit>().updateCondition(newCondition);
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    return Builder(
      builder: (context) {
        final currentCubitState = context.read<ConditionCubit>().state;
        if (currentCubitState is ConditionInitial) {
          context.read<ConditionCubit>().loadConditions();
        }

        return BlocListener<ConditionCubit, ConditionState>(
          listener: (context, state) {
            if (state is ConditionOperationSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is ConditionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Scaffold(
            appBar:
                Responsive.isDesktop(context)
                    ? null
                    : AppBar(
                      toolbarHeight: 10,
                      elevation: 0,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
            body: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Column(
                  children: [
                    _buildHeader(context, rs),

                    Expanded(
                      child: BlocBuilder<ConditionCubit, ConditionState>(
                        builder: (context, state) {
                          if (state is ConditionLoading ||
                              state is ConditionInitial) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (state is ConditionError) {
                            return Center(child: Text(state.message));
                          }

                          if (state is ConditionLoaded) {
                            final filteredBySystem =
                                state.conditions.where((c) {
                                  return _selectedBodySystem == null ||
                                      c.bodySystem == _selectedBodySystem;
                                }).toList();

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    right: 20,
                                    bottom: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Total: ${state.conditions.length}",
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
                                      filteredBySystem.isEmpty
                                          ? _buildEmptyView(state.searchQuery)
                                          : Responsive(
                                            mobile: MobileConditionList(
                                              conditions: filteredBySystem,
                                              rs: rs,
                                              onRefresh: () async {
                                                context
                                                    .read<ConditionCubit>()
                                                    .refreshConditions();
                                              },
                                              onEdit:
                                                  (cond) => _showAddEditDialog(
                                                    context: context,
                                                    condition: cond,
                                                  ),
                                              onDelete:
                                                  (cond) => _handleDelete(
                                                    context,
                                                    cond,
                                                  ),
                                            ),
                                            tablet: DesktopConditionList(
                                              conditions: filteredBySystem,
                                              rs: rs,
                                              onRefresh: () async {
                                                context
                                                    .read<ConditionCubit>()
                                                    .refreshConditions();
                                              },
                                              onEdit:
                                                  (cond) => _showAddEditDialog(
                                                    context: context,
                                                    condition: cond,
                                                  ),
                                              onDelete:
                                                  (cond) => _handleDelete(
                                                    context,
                                                    cond,
                                                  ),
                                            ),
                                            desktop: DesktopConditionList(
                                              conditions: filteredBySystem,
                                              rs: rs,
                                              onRefresh: () async {
                                                context
                                                    .read<ConditionCubit>()
                                                    .refreshConditions();
                                              },
                                              onEdit:
                                                  (cond) => _showAddEditDialog(
                                                    context: context,
                                                    condition: cond,
                                                  ),
                                              onDelete:
                                                  (cond) => _handleDelete(
                                                    context,
                                                    cond,
                                                  ),
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
            floatingActionButton: Builder(
              builder:
                  (context) => FloatingActionButton(
                    tooltip: 'Add Condition',
                    onPressed: () => _showAddEditDialog(context: context),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 4,
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ResponsiveSize rs) {
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.secondary,
              size: rs.appBarIcon,
            ),
          ),
          SizedBox(width: defaultPadding),
          Text(
            "Conditions",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
              fontSize: rs.appBarTitleFont,
            ),
          ),
        ],
      ),
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
                ? 'No conditions available'
                : 'No conditions found for "$query"',
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
              context.read<ConditionCubit>().searchConditions(value);
            },
            decoration: InputDecoration(
              hintText: 'Search conditions...',
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
          DropdownButtonFormField<BodySystem?>(
            initialValue: _selectedBodySystem,
            decoration: InputDecoration(
              hintText: 'Filter by body system',
              filled: true,
              fillColor: Theme.of(context).colorScheme.onPrimary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            items: [
              const DropdownMenuItem<BodySystem?>(
                value: null,
                child: Text('All Systems'),
              ),
              ...BodySystem.values.map((system) {
                return DropdownMenuItem<BodySystem?>(
                  value: system,
                  child: Text(bodySystemLabel(system)),
                );
              }),
            ],
            onChanged: (system) {
              setState(() {
                _selectedBodySystem = system;
              });
              context.read<ConditionCubit>().filterByBodySystem(system);
            },
          ),
        ],
      ),
    );
  }
}
