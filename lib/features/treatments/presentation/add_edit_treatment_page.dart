import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/model.dart';
import 'package:zim_herbs_repo/features/herbs/data/herb_repository.dart';
import 'package:zim_herbs_repo/features/herbs/data/models.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_models.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_repository.dart';
import 'package:zim_herbs_repo/features/treatments/bloc/treatment_form_bloc.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

/// Page for Creating and Editing Treatments.
/// Uses [TreatmentFormBloc] to manage state.
class AddEditTreatmentPage extends StatelessWidget {
  final TreatmentModel? treatment;
  const AddEditTreatmentPage({super.key, this.treatment});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => TreatmentFormBloc(
            herbRepository: HerbRepository(),
            treatmentRepository: TreatmentRepository(),
          )..add(LoadFormResources(treatment: treatment)),
      child: _TreatmentFormView(treatment: treatment),
    );
  }
}

class _TreatmentFormView extends StatefulWidget {
  final TreatmentModel? treatment;
  const _TreatmentFormView({this.treatment});

  @override
  State<_TreatmentFormView> createState() => _TreatmentFormViewState();
}

class _TreatmentFormViewState extends State<_TreatmentFormView> {
  final _formKey = GlobalKey<FormState>();

  // core controllers
  final _nameController = TextEditingController();
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

  ConditionModel? _selectedCondition;

  // We manage the TEXT controllers for the dynamic rows here in the UI state
  final List<_HerbRowControllers> _rowControllers = [];

  @override
  void initState() {
    super.initState();
    if (widget.treatment != null) {
      _nameController.text = widget.treatment!.name;
      _methodController.text = widget.treatment!.methodOfUse;
      _preparationController.text = widget.treatment!.preparation;
      _dosageInfantController.text = widget.treatment!.dosageInfants ?? '';
      _dosageAdultController.text = widget.treatment!.dosageAdults ?? '';
      _durationController.text = widget.treatment!.duration ?? '';
      _frequencyController.text = widget.treatment!.frequency ?? '';
      _notesController.text = widget.treatment!.notes ?? '';
      _precautionsController.text = widget.treatment!.precautions ?? '';
      _sideEffectsController.text = widget.treatment!.sideEffects ?? '';
      _disclaimerController.text = widget.treatment!.disclaimer ?? '';
      // Conditions and herbs will be handled by the Bloc listener once loaded
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  void _onSubmit(BuildContext context, TreatmentFormState state) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a condition')),
      );
      return;
    }

    List<TreatmentHerbModel> treatmentHerbs = [];

    for (int i = 0; i < state.herbRows.length; i++) {
      final rowState = state.herbRows[i];
      final controllers = _rowControllers[i];

      if (rowState.selectedHerb == null) {
        continue;
      }

      treatmentHerbs.add(
        TreatmentHerbModel(
          id: '',
          treatmentId: '',
          herbId: rowState.selectedHerb!.id,
          quantity: controllers.quantity.text,
          unit: controllers.unit.text,
          preparation: controllers.preparation.text,
        ),
      );
    }

    if (treatmentHerbs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one herb')),
      );
      return;
    }

    final treatment = TreatmentModel(
      id: widget.treatment?.id ?? '',
      conditionId: _selectedCondition!.id,
      name: _nameController.text,
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
      treatmentHerbs: treatmentHerbs,
      isApproved: widget.treatment?.isApproved ?? false,
      approvedAt: widget.treatment?.approvedAt,
      approvedBy: widget.treatment?.approvedBy,
    );

    context.read<TreatmentFormBloc>().add(SubmitTreatment(treatment));
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.treatment == null ? 'New Treatment' : 'Edit Treatment',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: BlocConsumer<TreatmentFormBloc, TreatmentFormState>(
        listener: (context, state) {
          if (state.status == TreatmentFormStatus.success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Treatment created successfully!')),
            );
          }
          if (state.status == TreatmentFormStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.errorMessage}')),
            );
          }
        },
        builder: (context, state) {
          if (state.status == TreatmentFormStatus.loaded) {
            if (widget.treatment != null && _selectedCondition == null) {
              try {
                _selectedCondition = state.conditions.firstWhere(
                  (c) => c.id == widget.treatment!.conditionId,
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

          if (state.status == TreatmentFormStatus.loading) {
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

                  _buildTextField(
                    controller: _nameController,
                    label: 'Treatment Name',
                    rs: rs,
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),

                  _SearchableDropdown<ConditionModel>(
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
                    'Add herbs and their specific quantities for this treatment.',
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
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                          () => context.read<TreatmentFormBloc>().add(
                            AddHerbRow(),
                          ),
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
                  // Use Column for mobile, Row for tablet/desktop
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
                  // Use Column for mobile, Row for tablet/desktop
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
                          state.status == TreatmentFormStatus.submitting
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
                          state.status == TreatmentFormStatus.submitting
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                widget.treatment == null
                                    ? 'CREATE TREATMENT'
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
    List<HerbModel> herbs,
    TreatmentHerbRow rowState,
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
                child: _SearchableDropdown<HerbModel>(
                  value: rowState.selectedHerb,
                  items: herbs,
                  label: 'Select Herb',
                  rs: rs,
                  itemLabelBuilder: (h) => h.nameEn,
                  onChanged: (val) {
                    if (val != null) {
                      context.read<TreatmentFormBloc>().add(
                        HerbSelected(index: index, herb: val),
                      );
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  context.read<TreatmentFormBloc>().add(RemoveHerbRow(index));
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Use Column for mobile, Row for tablet/desktop
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

class _SearchableDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String label;
  final String Function(T) itemLabelBuilder;
  final void Function(T?) onChanged;
  final ResponsiveSize rs;
  final String? Function(T?)? validator;

  const _SearchableDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.itemLabelBuilder,
    required this.onChanged,
    required this.rs,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // We recreate the exact same decoration as the text fields
    // but use a GestureDetector to open the dialog.
    return InkWell(
      onTap: () async {
        final T? result = await showDialog<T>(
          context: context,
          builder:
              (context) => _SearchDialog<T>(
                items: items,
                itemLabelBuilder: itemLabelBuilder,
                label: label,
              ),
        );
        if (result != null) {
          onChanged(result);
        }
      },
      child: InputDecorator(
        decoration: (context
                    .findAncestorStateOfType<_TreatmentFormViewState>() ??
                (throw StateError('_TreatmentFormViewState not found')))
            ._inputDecoration(context, rs, label),
        isEmpty: value == null,
        child: Builder(
          builder: (context) {
            final currentValue = value;
            return Text(
              currentValue == null ? '' : itemLabelBuilder(currentValue),
              style: TextStyle(fontSize: rs.bodyFont),
            );
          },
        ),
      ),
    );
  }
}

class _SearchDialog<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final String label;

  const _SearchDialog({
    required this.items,
    required this.itemLabelBuilder,
    required this.label,
  });

  @override
  State<_SearchDialog<T>> createState() => _SearchDialogState<T>();
}

class _SearchDialogState<T> extends State<_SearchDialog<T>> {
  List<T> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _filteredItems = widget.items);
      return;
    }
    setState(() {
      _filteredItems =
          widget.items
              .where(
                (item) => widget
                    .itemLabelBuilder(item)
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ${widget.label}...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filter,
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child:
                _filteredItems.isEmpty
                    ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No results found'),
                    )
                    : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      separatorBuilder:
                          (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return ListTile(
                          title: Text(widget.itemLabelBuilder(item)),
                          onTap: () {
                            Navigator.pop(context, item);
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
