import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/conditions/bloc/condition_bloc.dart';
import 'package:zim_herbs_repo/features/conditions/bloc/condition_event.dart';
import 'package:zim_herbs_repo/features/conditions/bloc/condition_state.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/condition_repository.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/model.dart';
import 'package:zim_herbs_repo/features/conditions/presentation/components/add_edit_condition_dialog.dart';
import 'package:zim_herbs_repo/features/conditions/presentation/components/desktop_condition_list.dart';
import 'package:zim_herbs_repo/features/conditions/presentation/components/mobile_condition_list.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/enums.dart';

class ConditionsListPage extends StatefulWidget {
  const ConditionsListPage({super.key});

  @override
  State<ConditionsListPage> createState() => _ConditionsListPageState();
}

class _ConditionsListPageState extends State<ConditionsListPage> {
  final ConditionRepository _repository = ConditionRepository();

  // We no longer need all these variables! The BLoC holds our state now.
  BodySystem? _selectedBodySystem;

  @override
  void initState() {
    super.initState();
    // In BLoC, we usually don't need initState for fetching if we use ..add(LoadConditions()) in provider
  }

  // No more manual filtering!

  Future<void> _handleDelete(ConditionModel condition) async {
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

    if (confirm == true) {
      try {
        await _repository.deleteCondition(condition.id);

        // Human: We tell the Chef to reload.
        if (mounted) {
          context.read<ConditionBloc>().add(RefreshConditions());
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Condition deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting condition: $e')),
          );
        }
      }
    }
  }

  Future<void> _showAddEditDialog({
    required BuildContext context,
    ConditionModel? condition,
  }) async {
    await showDialog(
      context: context,
      builder:
          (context) => AddEditConditionDialog(
            condition: condition,
            onSave: (newCondition) async {
              try {
                if (condition == null) {
                  await _repository.createCondition(newCondition);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Condition added')),
                    );
                  }
                } else {
                  await _repository.updateCondition(newCondition);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Condition updated')),
                    );
                  }
                }
                // Human: Refresh the chef!
                if (context.mounted) {
                  context.read<ConditionBloc>().add(RefreshConditions());
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving condition: $e')),
                  );
                }
                rethrow;
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    // STEP 1: Wrap in BlocProvider
    return BlocProvider(
      create: (context) => ConditionBloc(_repository)..add(LoadConditions()),
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
                // Branded Header
                _buildHeader(context, rs),

                // STEP 2: Use BlocBuilder for the content
                Expanded(
                  child: BlocBuilder<ConditionBloc, ConditionState>(
                    builder: (context, state) {
                      // Case A: Chef is busy
                      if (state is ConditionLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Case B: Error
                      if (state is ConditionError) {
                        return Center(child: Text(state.message));
                      }

                      // Case C: Success
                      if (state is ConditionLoaded) {
                        // We still filter by body system in the UI for now
                        // as it's a simpler local UI filter for this feature
                        final filteredBySystem =
                            state.conditions.where((c) {
                              return _selectedBodySystem == null ||
                                  c.bodySystem == _selectedBodySystem;
                            }).toList();

                        return Column(
                          children: [
                            // Counter
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withValues(alpha: 0.7),
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
                                            context.read<ConditionBloc>().add(
                                              RefreshConditions(),
                                            );
                                          },
                                          onEdit:
                                              (condition) => _showAddEditDialog(
                                                context: context,
                                                condition: condition,
                                              ),
                                          onDelete: _handleDelete,
                                        ),
                                        tablet: DesktopConditionList(
                                          conditions: filteredBySystem,
                                          rs: rs,
                                          onRefresh: () async {
                                            context.read<ConditionBloc>().add(
                                              RefreshConditions(),
                                            );
                                          },
                                          onEdit:
                                              (condition) => _showAddEditDialog(
                                                context: context,
                                                condition: condition,
                                              ),
                                          onDelete: _handleDelete,
                                        ),
                                        desktop: DesktopConditionList(
                                          conditions: filteredBySystem,
                                          rs: rs,
                                          onRefresh: () async {
                                            context.read<ConditionBloc>().add(
                                              RefreshConditions(),
                                            );
                                          },
                                          onEdit:
                                              (condition) => _showAddEditDialog(
                                                context: context,
                                                condition: condition,
                                              ),
                                          onDelete: _handleDelete,
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
              // Human: Send the search order to the chef!
              context.read<ConditionBloc>().add(SearchConditions(value));
            },
            // Use a controller or initial value if we wanted the text to persist during redraws
            // but for simple real-time it works
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
            },
          ),
        ],
      ),
    );
  }
}
