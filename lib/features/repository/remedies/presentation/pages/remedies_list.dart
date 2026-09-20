import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zim_herbs_repo/features/admin/remedy_management/presentation/add_edit_remedy_page.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/datasources/condition_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/models/condition_model.dart';
import 'package:zim_herbs_repo/features/repository/remedies/data/datasources/remedy_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/remedies/data/repositories/remedy_repository_impl.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/components/desktop_remedy_list.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/components/mobile_remedy_list.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/cubit/remedy_cubit.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/cubit/remedy_state.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/core/components/searchable_dropdown.dart';

class RemediesList extends StatelessWidget {
  final String? initialConditionId;

  const RemediesList({super.key, this.initialConditionId});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    final repository = RemedyRepositoryImpl(
      RemedyRemoteDataSource(client),
    );

    return BlocProvider(
      create: (context) {
        final cubit = RemedyCubit(repository);
        if (initialConditionId != null) {
          cubit.filterByCondition(initialConditionId);
        } else {
          cubit.loadRemedies();
        }
        return cubit;
      },
      child: _RemediesListView(initialConditionId: initialConditionId),
    );
  }
}

class _RemediesListView extends StatelessWidget {
  final String? initialConditionId;
  const _RemediesListView({this.initialConditionId});

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final conditionsFuture =
        ConditionRemoteDataSource(Supabase.instance.client).getAllConditions();

    return Scaffold(
      appBar:
          Responsive.isDesktop(context)
              ? null
              : AppBar(
                toolbarHeight: 10,
                elevation: 0,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Remedy',
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
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: BlocListener<RemedyCubit, RemedyState>(
            listener: (context, state) {
              if (state is RemedyOperationSuccess) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              } else if (state is RemedyError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Column(
              children: [
                // Header
                _buildHeader(context, rs),

                // Counter
                BlocBuilder<RemedyCubit, RemedyState>(
                  builder: (context, state) {
                    if (state is RemedyLoaded) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          top: 8,
                          right: 20,
                          bottom: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Total: ${state.remedies.length}",
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
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Search & Filter
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: rs.defaultPadding,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      // Search field
                      TextField(
                        onChanged:
                            (value) =>
                                context.read<RemedyCubit>().searchRemedies(
                                  value,
                                ),
                        decoration: InputDecoration(
                          hintText: 'Search remedies by herb or condition...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
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
                        future: conditionsFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          ConditionModel? initialSelected;
                          if (initialConditionId != null) {
                            try {
                              initialSelected = snapshot.data!.firstWhere(
                                (c) => c.id == initialConditionId,
                              );
                            } catch (_) {}
                          }

                          return _ConditionFilterDropdown(
                            conditions: snapshot.data!,
                            initialValue: initialSelected,
                            onConditionSelected: (selected) {
                              context.read<RemedyCubit>().filterByCondition(
                                selected?.id,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: BlocBuilder<RemedyCubit, RemedyState>(
                    builder: (context, state) {
                      if (state is RemedyLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is RemedyError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                state.message,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed:
                                    () =>
                                        context
                                            .read<RemedyCubit>()
                                            .refreshRemedies(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is RemedyLoaded) {
                        if (state.remedies.isEmpty) {
                          return Center(
                            child: Text(
                              state.searchQuery.isNotEmpty
                                  ? 'No remedies matching "${state.searchQuery}"'
                                  : 'No remedies found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh:
                              () =>
                                  context.read<RemedyCubit>().refreshRemedies(),
                          child:
                              (Responsive.isMobile(context)
                                  ? MobileRemedyList(
                                        remedies: state.remedies,
                                        rs: rs,
                                      )
                                      as Widget
                                  : DesktopRemedyList(
                                        remedies: state.remedies,
                                        rs: rs,
                                      )
                                      as Widget),
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
  }

  Widget _buildHeader(BuildContext context, ResponsiveSize rs) {
    return Container(
      padding: EdgeInsets.all(rs.defaultPadding),
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
          SizedBox(width: rs.defaultPadding),
          Text(
            "All Remedies",
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
}

class _ConditionFilterDropdown extends StatefulWidget {
  final List<ConditionModel> conditions;
  final ConditionModel? initialValue;
  final Function(ConditionModel?) onConditionSelected;

  const _ConditionFilterDropdown({
    required this.conditions,
    this.initialValue,
    required this.onConditionSelected,
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
    final rs = ResponsiveSize(context);
    return Row(
      children: [
        Expanded(
          child: SearchableDropdown<ConditionModel>(
            value: _selectedCondition,
            items: widget.conditions,
            label: 'Filter by Condition',
            rs: rs,
            itemLabelBuilder: (c) => c.name,
            onChanged: (val) {
              setState(() {
                _selectedCondition = val;
              });
              widget.onConditionSelected(val);
            },
          ),
        ),
        if (_selectedCondition != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _selectedCondition = null;
              });
              widget.onConditionSelected(null);
            },
            tooltip: 'Clear Filter',
          ),
      ],
    );
  }
}
