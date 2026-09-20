import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/datasources/condition_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/repositories/condition_repository_impl.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/entities/condition.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/datasources/herb_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/repositories/herb_repository_impl.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';
import 'package:zim_herbs_repo/features/repository/remedies/data/datasources/remedy_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/remedies/data/repositories/remedy_repository_impl.dart';
import 'package:zim_herbs_repo/features/repository/remedies/domain/entities/remedy.dart';
import 'package:zim_herbs_repo/core/components/searchable_dropdown.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/cubit/remedy_form_cubit.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';

/// Page for Creating and Editing Remedies.
/// Uses [RemedyFormCubit] to manage state.
class AddEditRemedyPage extends StatelessWidget {
  final Remedy? remedy;
  const AddEditRemedyPage({super.key, this.remedy});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final client = Supabase.instance.client;
        final herbDataSource = HerbRemoteDataSource(client);
        final herbRepository = HerbRepositoryImpl(herbDataSource);
        final conditionDataSource = ConditionRemoteDataSource(client);
        final conditionRepository = ConditionRepositoryImpl(conditionDataSource);
        final remedyRepository = RemedyRepositoryImpl(
          RemedyRemoteDataSource(client),
        );
        return RemedyFormCubit(
          herbRepository: herbRepository,
          remedyRepository: remedyRepository,
          conditionRepository: conditionRepository,
        )..loadFormResources(remedy);
      },
      child: _RemedyFormView(remedy: remedy),
    );
  }
}

class _RemedyFormView extends StatefulWidget {
  final Remedy? remedy;
  const _RemedyFormView({this.remedy});

  @override
  State<_RemedyFormView> createState() => _RemedyFormViewState();
}

class _RemedyFormViewState extends State<_RemedyFormView> {
  final _formKey = GlobalKey<FormState>();

  // core controllers
  final _methodController = TextEditingController();
  final _preparationController = TextEditingController();
  final _dosageInfantController = TextEditingController();
  final _dosageAdultController = TextEditingController();
  final _durationController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _notesController = TextEditingController();
  final _precautionsController = TextEditingController();
  final _sideEffectsController = TextEditingController();
  final _disclaimerController = TextEditingController();

  Condition? _selectedCondition;

  // We manage the TEXT controllers for the dynamic rows here in the UI state
  final List<_HerbRowControllers> _rowControllers = [];

  @override
  void initState() {
    super.initState();
    if (widget.remedy != null) {
      _methodController.text = widget.remedy!.methodOfUse;
      _preparationController.text = widget.remedy!.preparation;
      _dosageInfantController.text = widget.remedy!.dosageInfants ?? '';
      _dosageAdultController.text = widget.remedy!.dosageAdults ?? '';
      _durationController.text = widget.remedy!.duration ?? '';
      _frequencyController.text = widget.remedy!.frequency ?? '';
      _notesController.text = widget.remedy!.notes ?? '';
      _precautionsController.text = widget.remedy!.precautions ?? '';
      _sideEffectsController.text = widget.remedy!.sideEffects ?? '';
      _disclaimerController.text = widget.remedy!.disclaimer ?? '';
    }
  }

  @override
  void dispose() {
    _methodController.dispose();
    _preparationController.dispose();
    _dosageInfantController.dispose();
    _dosageAdultController.dispose();
    _durationController.dispose();
    _frequencyController.dispose();
    _notesController.dispose();
    _precautionsController.dispose();
    _sideEffectsController.dispose();
    _disclaimerController.dispose();
    for (var c in _rowControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onSubmit(BuildContext context, RemedyFormState state) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a condition')),
      );
      return;
    }

    List<RemedyHerb> remedyHerbs = [];

    for (int i = 0; i < state.herbRows.length; i++) {
      final rowState = state.herbRows[i];
      final controllers = _rowControllers[i];

      if (rowState.selectedHerb == null) {
        continue;
      }

      remedyHerbs.add(
        RemedyHerb(
          id: '',
          remedyId: '',
          herbId: rowState.selectedHerb!.id,
          quantity: controllers.quantity.text.isEmpty ? null : controllers.quantity.text,
          unit: controllers.unit.text.isEmpty ? null : controllers.unit.text,
          preparation: controllers.preparation.text.isEmpty ? null : controllers.preparation.text,
          herbName: rowState.selectedHerb!.nameEn,
          herbImageUrl: rowState.selectedHerb!.primaryImageUrl,
        ),
      );
    }

    if (remedyHerbs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one herb')),
      );
      return;
    }

    // Auto-generate name from the selected herbs (e.g. "Aloe vera + Moringa").
    // This keeps the DB column populated without requiring manual input.
    final generatedName = remedyHerbs
        .map((rh) => rh.herbName ?? '')
        .where((n) => n.isNotEmpty)
        .join(' + ');

    final remedy = Remedy(
      id: widget.remedy?.id ?? '',
      conditionId: _selectedCondition!.id,
      name: generatedName.isNotEmpty
          ? generatedName
          : widget.remedy?.name ?? 'Remedy',
      methodOfUse: _methodController.text,
      preparation: _preparationController.text,
      dosageInfants:
          _dosageInfantController.text.isEmpty
              ? null
              : _dosageInfantController.text,
      dosageAdults:
          _dosageAdultController.text.isEmpty
              ? null
              : _dosageAdultController.text,
      duration:
          _durationController.text.isEmpty ? null : _durationController.text,
      frequency:
          _frequencyController.text.isEmpty ? null : _frequencyController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      precautions:
          _precautionsController.text.isEmpty
              ? null
              : _precautionsController.text,
      sideEffects:
          _sideEffectsController.text.isEmpty
              ? null
              : _sideEffectsController.text,
      disclaimer:
          _disclaimerController.text.isEmpty
              ? null
              : _disclaimerController.text,
      remedyHerbs: remedyHerbs,
      isApproved: widget.remedy?.isApproved ?? false,
      approvedAt: widget.remedy?.approvedAt,
      approvedBy: widget.remedy?.approvedBy,
    );

    context.read<RemedyFormCubit>().submitRemedy(remedy);
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.remedy == null ? 'New Remedy' : 'Edit Remedy',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: BlocConsumer<RemedyFormCubit, RemedyFormState>(
        listener: (context, state) {
          if (state.status == RemedyFormStatus.success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Remedy saved successfully!')),
            );
          }
          if (state.status == RemedyFormStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.errorMessage}')),
            );
          }
        },
        builder: (context, state) {
          if (state.status == RemedyFormStatus.loaded) {
            if (widget.remedy != null && _selectedCondition == null) {
              try {
                _selectedCondition = state.conditions.firstWhere(
                  (c) => c.id == widget.remedy!.conditionId,
                );
              } catch (_) {}
            }
          }

          while (_rowControllers.length < state.herbRows.length) {
            final index = _rowControllers.length;
            final controllers = _HerbRowControllers();
            final rowState = state.herbRows[index];
            controllers.quantity.text = rowState.quantity;
            controllers.unit.text = rowState.unit;
            controllers.preparation.text = rowState.preparation;
            _rowControllers.add(controllers);
          }
          while (_rowControllers.length > state.herbRows.length) {
            _rowControllers.removeLast().dispose();
          }

          if (state.status == RemedyFormStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(rs.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Basic Info', rs),
                  const SizedBox(height: 10),

                  SearchableDropdown<Condition>(
                    value: _selectedCondition,
                    items: state.conditions,
                    label: 'Condition',
                    rs: rs,
                    itemLabelBuilder: (c) => c.name,
                    onChanged:
                        (val) => setState(() => _selectedCondition = val),
                    validator: (v) => v == null ? 'Required' : null,
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle('Herbs & Ingredients', rs),
                  Text(
                    'Add herbs and their specific quantities for this remedy.',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: rs.bodyFont,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.herbRows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildHerbRow(
                        context,
                        index,
                        state.availableHerbs,
                        state.herbRows[index],
                        _rowControllers[index],
                        rs,
                      );
                    },
                  ),

                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed:
                          () => context.read<RemedyFormCubit>().addHerbRow(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Another Herb'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.secondary,
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: rs.labelFont,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle('Instructions', rs),
                  const SizedBox(height: 10),

                  _buildTextField(
                    controller: _methodController,
                    label: 'Method of Use',
                    rs: rs,
                    maxLines: 2,
                    hintText: 'e.g. Boil water, add leaves...',
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _preparationController,
                    label: 'Preparation',
                    rs: rs,
                    maxLines: 2,
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle('Dosage & Details', rs),
                  const SizedBox(height: 10),
                  rs.isMobile
                      ? Column(
                        children: [
                          _buildTextField(
                            controller: _dosageAdultController,
                            label: 'Adult Dosage',
                            rs: rs,
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _dosageInfantController,
                            label: 'Infant Dosage',
                            rs: rs,
                          ),
                        ],
                      )
                      : Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _dosageAdultController,
                              label: 'Adult Dosage',
                              rs: rs,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: _dosageInfantController,
                              label: 'Infant Dosage',
                              rs: rs,
                            ),
                          ),
                        ],
                      ),
                  const SizedBox(height: 10),
                  rs.isMobile
                      ? Column(
                        children: [
                          _buildTextField(
                            controller: _frequencyController,
                            label: 'Frequency',
                            rs: rs,
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _durationController,
                            label: 'Duration',
                            rs: rs,
                          ),
                        ],
                      )
                      : Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _frequencyController,
                              label: 'Frequency',
                              rs: rs,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: _durationController,
                              label: 'Duration',
                              rs: rs,
                            ),
                          ),
                        ],
                      ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _precautionsController,
                    label: 'Precautions',
                    rs: rs,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _sideEffectsController,
                    label: 'Side Effects',
                    rs: rs,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          state.status == RemedyFormStatus.submitting
                              ? null
                              : () => _onSubmit(context, state),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          state.status == RemedyFormStatus.submitting
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                widget.remedy == null
                                    ? 'CREATE REMEDY'
                                    : 'SAVE CHANGES',
                                style: TextStyle(
                                  fontSize: rs.subtitleFont,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, ResponsiveSize rs) {
    return Text(
      title,
      style: TextStyle(
        fontSize: rs.titleFont,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    ResponsiveSize rs,
    String label, {
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: rs.labelFont,
      ),
      hintStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        fontSize: rs.labelFont,
      ),
      floatingLabelStyle: TextStyle(
        color: Theme.of(context).colorScheme.secondary,
        fontWeight: FontWeight.bold,
        fontSize: rs.labelFont,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.onPrimary,
      suffixIcon: const Icon(Icons.arrow_drop_down),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ResponsiveSize rs,
    int maxLines = 1,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(
        context,
        rs,
        label,
        hintText: hintText,
      ).copyWith(suffixIcon: null),
      validator: validator,
    );
  }

  Widget _buildHerbRow(
    BuildContext context,
    int index,
    List<Herb> herbs,
    RemedyHerbRow rowState,
    _HerbRowControllers controllers,
    ResponsiveSize rs,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SearchableDropdown<Herb>(
                  value: rowState.selectedHerb,
                  items: herbs,
                  label: 'Select Herb',
                  rs: rs,
                  itemLabelBuilder: (h) => h.nameEn,
                  onChanged: (val) {
                    if (val != null) {
                      context.read<RemedyFormCubit>().selectHerb(index, val);
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  context.read<RemedyFormCubit>().removeHerbRow(index);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          rs.isMobile
              ? Column(
                children: [
                  _buildTextField(
                    controller: controllers.quantity,
                    label: 'Qty',
                    hintText: '2',
                    rs: rs,
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: controllers.unit,
                    label: 'Unit',
                    hintText: 'cups',
                    rs: rs,
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: controllers.preparation,
                    label: 'Prep Note',
                    hintText: 'chopped',
                    rs: rs,
                  ),
                ],
              )
              : Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: controllers.quantity,
                      label: 'Qty',
                      hintText: '2',
                      rs: rs,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: controllers.unit,
                      label: 'Unit',
                      hintText: 'cups',
                      rs: rs,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: controllers.preparation,
                      label: 'Prep Note',
                      hintText: 'chopped',
                      rs: rs,
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}

class _HerbRowControllers {
  final TextEditingController quantity = TextEditingController();
  final TextEditingController unit = TextEditingController();
  final TextEditingController preparation = TextEditingController();

  void dispose() {
    quantity.dispose();
    unit.dispose();
    preparation.dispose();
  }
}
