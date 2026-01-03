import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_repository.dart';
import 'package:zim_herbs_repo/features/treatments/bloc/treatment_bloc.dart';
import 'package:zim_herbs_repo/features/treatments/presentation/add_edit_treatment_page.dart';
import 'package:zim_herbs_repo/features/treatments/presentation/components/desktop_treatment_list.dart';
import 'package:zim_herbs_repo/features/treatments/presentation/components/mobile_treatment_list.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/components/searchable_dropdown.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/condition_repository.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/model.dart';

class TreatmentsList extends StatelessWidget {
  final String? initialConditionId;

  const TreatmentsList({super.key, this.initialConditionId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => TreatmentBloc(TreatmentRepository())
            ..add(
              initialConditionId != null
                  ? FilterTreatmentsByCondition(initialConditionId)
                  : LoadTreatments(),
            ),
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
    final conditionsFuture = ConditionRepository().getAllConditions();

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
            context.read<TreatmentBloc>().add(RefreshTreatments());
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
          child: Column(
            children: [
              // Header
              _buildHeader(context, rs),

              // Counter
              BlocBuilder<TreatmentBloc, TreatmentState>(
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
                        return BlocBuilder<TreatmentBloc, TreatmentState>(
                          builder: (context, state) {
                            return _ConditionFilterDropdown(
                              conditions: conditions,
                              initialValue: initialCondition,
                              onConditionSelected: (c) {
                                context.read<TreatmentBloc>().add(
                                  FilterTreatmentsByCondition(c?.id),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: BlocBuilder<TreatmentBloc, TreatmentState>(
                  builder: (context, state) {
                    if (state is TreatmentLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is TreatmentError) {
                      return Center(child: Text('Error: ${state.message}'));
                    }
                    if (state is TreatmentLoaded) {
                      if (state.treatments.isEmpty) {
                        return const Center(child: Text('No treatments found.'));
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<TreatmentBloc>().add(
                            RefreshTreatments(),
                          );
                        },
                        child:
                            Responsive.isMobile(context)
                                ? MobileTreatmentList(
                                  treatments: state.treatments,
                                  rs: rs,
                                )
                                : DesktopTreatmentList(
                                  treatments: state.treatments,
                                  rs: rs,
                                ),
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
