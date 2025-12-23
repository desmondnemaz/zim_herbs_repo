import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_repository.dart';
import 'package:zim_herbs_repo/features/treatments/bloc/treatment_bloc.dart';
import 'package:zim_herbs_repo/features/treatments/presentation/add_edit_treatment_page.dart';
import 'package:zim_herbs_repo/features/treatments/presentation/treatment_details.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

class TreatmentsList extends StatelessWidget {
  const TreatmentsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              TreatmentBloc(TreatmentRepository())..add(LoadTreatments()),
      child: const _TreatmentsListView(),
    );
  }
}

class _TreatmentsListView extends StatelessWidget {
  const _TreatmentsListView();

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

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

              // Search Bar (Simple implementation matching Herbs style)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  onChanged: (value) {
                    context.read<TreatmentBloc>().add(SearchTreatments(value));
                  },
                  decoration: InputDecoration(
                    hintText: "Search treatments...",
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
                        return const Center(
                          child: Text('No treatments found.'),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<TreatmentBloc>().add(
                            RefreshTreatments(),
                          );
                        },
                        child: ListView.separated(
                          padding: EdgeInsets.all(rs.defaultPadding),
                          itemCount: state.treatments.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final treatment = state.treatments[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                title: Text(
                                  treatment.name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    if (treatment.condition != null)
                                      Chip(
                                        label: Text(
                                          treatment.condition!.name,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor:
                                            Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${treatment.treatmentHerbs.length} Herbs',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => TreatmentDetailsPage(
                                            treatmentId: treatment.id,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
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
          BlocBuilder<TreatmentBloc, TreatmentState>(
            builder: (context, state) {
              String title = "All Treatments";
              if (state is TreatmentLoaded) {
                title = "All Treatments (${state.treatments.length})";
              }
              return Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: rs.appBarTitleFont,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
