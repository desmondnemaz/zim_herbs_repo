import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/model.dart';
import 'package:zim_herbs_repo/utils/enums.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

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
    return AlertDialog(
      title: Text(
        widget.condition == null ? 'Add Condition' : 'Edit Condition',
        style: TextStyle(fontSize: rs.titleFont, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    fontSize: rs.labelFont,
                    color: Theme.of(context).colorScheme.primary,
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
                  fillColor: Theme.of(context).colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    fontSize: rs.labelFont,
                    color: Theme.of(context).colorScheme.primary,
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
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    fontSize: rs.labelFont,
                    color: Theme.of(context).colorScheme.primary,
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
                  fillColor: Theme.of(context).colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    fontSize: rs.labelFont,
                    color: Theme.of(context).colorScheme.primary,
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
                  fillColor: Theme.of(context).colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    fontSize: rs.labelFont,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                maxLines: 2,
              ),
            ],
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
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
      );

      widget.onSave(newCondition);
      Navigator.pop(context);
    }
  }
}
