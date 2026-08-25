import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zim_herbs_repo/features/admin/treatment_management/presentation/add_edit_treatment_page.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/datasources/condition_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/models/condition_model.dart';
import 'package:zim_herbs_repo/features/repository/treatments/data/datasources/treatment_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/treatments/data/repositories/treatment_repository_impl.dart';
import 'package:zim_herbs_repo/features/repository/treatments/presentation/components/desktop_treatment_list.dart';
import 'package:zim_herbs_repo/features/repository/treatments/presentation/components/mobile_treatment_list.dart';
import 'package:zim_herbs_repo/features/repository/treatments/presentation/cubit/treatment_cubit.dart';
import 'package:zim_herbs_repo/features/repository/treatments/presentation/cubit/treatment_state.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/core/components/searchable_dropdown.dart';

class TreatmentsList extends StatelessWidget {
  final String? initialConditionId;

  const TreatmentsList({super.key, this.initialConditionId});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    final repository = TreatmentRepositoryImpl(
      TreatmentRemoteDataSource(client),
    );

    return BlocProvider(
      create: (context) {
        final cubit = TreatmentCubit(repository);
        if (initialConditionId != null) {
          cubit.filterByCondition(initialConditionId);
        } else {
          cubit.loadTreatments();
        }
        return cubit;
      },
      child: _TreatmentsListView(initialConditionId: initialConditionId),
    );
  }
}

class _TreatmentsListView extends StatelessWidget {
  final String? initialConditionId;
  const _TreatmentsListView({this.initialConditionId});

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
        tooltip: 'Add Treatment',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditTreatmentPage(),
            ),
          );
          if (!context.mounted) return;
          if (result == true) {
            context.read<TreatmentCubit>().refreshTreatments();
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
          child: BlocListener<TreatmentCubit, TreatmentState>(
            listener: (context, state) {
              if (state is TreatmentOperationSuccess) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              } else if (state is TreatmentError) {
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
                BlocBuilder<TreatmentCubit, TreatmentState>(
                  builder: (context, state) {
                    if (state is TreatmentLoaded) {
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
                              "Total: ${state.treatments.length}",
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

                // Filter & Search Section
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // Condition Filter
                      FutureBuilder<List<ConditionModel>>(
                        future: conditionsFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          final conditions = snapshot.data!;
                          ConditionModel? initialCondition;
                          if (initialConditionId != null) {
                            try {
                              initialCondition = conditions.firstWhere(
                                (c) => c.id == initialConditionId,
                              );
                            } catch (_) {}
                          }
                          return _ConditionFilterDropdown(
                            conditions: conditions,
                            initialValue: initialCondition,
                            onConditionSelected: (c) {
                              context.read<TreatmentCubit>().filterByCondition(
                                c?.id,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: BlocBuilder<TreatmentCubit, TreatmentState>(
                    builder: (context, state) {
                      if (state is TreatmentLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is TreatmentLoaded) {
                        if (state.treatments.isEmpty) {
                          return const Center(
                            child: Text('No treatments found.'),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            context
                                .read<TreatmentCubit>()
                                .refreshTreatments();
                          },
                          child:
                              (Responsive.isMobile(context)
                                  ? MobileTreatmentList(
                                        treatments: state.treatments,
                                        rs: rs,
                                      )
                                      as Widget
                                  : DesktopTreatmentList(
                                        treatments: state.treatments,
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
            "All Treatments",
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
