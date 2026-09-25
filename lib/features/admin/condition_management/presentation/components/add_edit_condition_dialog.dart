import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/datasources/condition_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/models/body_part_model.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/models/condition_model.dart';

class AddEditConditionDialog extends StatefulWidget {
  final ConditionModel? condition;
  final Function(ConditionModel) onSave;

  const AddEditConditionDialog({
    super.key,
    this.condition,
    required this.onSave,
  });

  @override
  State<AddEditConditionDialog> createState() => _AddEditConditionDialogState();
}

class _AddEditConditionDialogState extends State<AddEditConditionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _symptomsController;
  late TextEditingController _precautionsController;
  BodySystem _selectedBodySystem = BodySystem.circulatory;

  List<BodyPartModel> _allBodyParts = [];
  final Set<String> _selectedBodyPartIds = {};
  bool _isLoadingBodyParts = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.condition?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.condition?.description ?? '',
    );
    _symptomsController = TextEditingController(
      text: widget.condition?.symptoms.join(', ') ?? '',
    );
    _precautionsController = TextEditingController(
      text: widget.condition?.precautions.join(', ') ?? '',
    );
    if (widget.condition != null) {
      _selectedBodySystem = widget.condition!.bodySystem;
      _selectedBodyPartIds.addAll(
        widget.condition!.bodyParts.map((bp) => bp.id),
      );
    }
    _loadBodyParts();
  }

  Future<void> _loadBodyParts() async {
    try {
      final dataSource = ConditionRemoteDataSource(Supabase.instance.client);
      final bodyParts = await dataSource.getAllBodyParts();
      if (mounted) {
        setState(() {
          _allBodyParts = bodyParts;
          _isLoadingBodyParts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingBodyParts = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _symptomsController.dispose();
    _precautionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        widget.condition == null ? 'Add Condition' : 'Edit Condition',
        style: TextStyle(fontSize: rs.titleFont, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: theme.colorScheme.onPrimary,
                    labelStyle: TextStyle(
                      fontSize: rs.labelFont,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BodySystem>(
                  initialValue: _selectedBodySystem,
                  decoration: InputDecoration(
                    labelText: 'Body System',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: theme.colorScheme.onPrimary,
                    labelStyle: TextStyle(
                      fontSize: rs.labelFont,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  items:
                      BodySystem.values.map((system) {
                        return DropdownMenuItem(
                          value: system,
                          child: Text(bodySystemLabel(system)),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedBodySystem = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Body Parts Affected section
                Text(
                  'Affected Body Parts',
                  style: TextStyle(
                    fontSize: rs.labelFont,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isLoadingBodyParts)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (_allBodyParts.isEmpty)
                  Text(
                    'No body parts found in database.',
                    style: TextStyle(
                      fontSize: rs.bodyFont * 0.9,
                      color: Colors.grey,
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        _allBodyParts.map((bp) {
                          final isSelected = _selectedBodyPartIds.contains(
                            bp.id,
                          );
                          final label =
                              bp.nameSn != null && bp.nameSn!.isNotEmpty
                                  ? '${bp.nameEn} (${bp.nameSn})'
                                  : bp.nameEn;

                          return FilterChip(
                            label: Text(label),
                            selected: isSelected,
                            selectedColor:
                                theme.colorScheme.primary.withValues(alpha: 0.2),
                            checkmarkColor: theme.colorScheme.primary,
                            labelStyle: TextStyle(
                              fontSize: rs.bodyFont * 0.85,
                              color:
                                  isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedBodyPartIds.add(bp.id);
                                } else {
                                  _selectedBodyPartIds.remove(bp.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: theme.colorScheme.onPrimary,
                    labelStyle: TextStyle(
                      fontSize: rs.labelFont,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _symptomsController,
                  decoration: InputDecoration(
                    labelText: 'Symptoms (comma separated)',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: theme.colorScheme.onPrimary,
                    labelStyle: TextStyle(
                      fontSize: rs.labelFont,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _precautionsController,
                  decoration: InputDecoration(
                    labelText: 'Precautions (comma separated)',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: theme.colorScheme.onPrimary,
                    labelStyle: TextStyle(
                      fontSize: rs.labelFont,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: Text(
            'Save',
            style: TextStyle(
              fontSize: rs.subtitleFont,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final symptoms =
          _symptomsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
      final precautions =
          _precautionsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      final selectedBodyParts =
          _allBodyParts
              .where((bp) => _selectedBodyPartIds.contains(bp.id))
              .toList();

      final newCondition = ConditionModel(
        id: widget.condition?.id ?? const Uuid().v4(),
        name: _nameController.text,
        bodySystem: _selectedBodySystem,
        description:
            _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
        symptoms: symptoms,
        precautions: precautions,
        bodyParts: selectedBodyParts,
      );

      widget.onSave(newCondition);
      Navigator.pop(context);
    }
  }
}
