import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/repository/ailments/data/datasources/ailment_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/ailments/data/models/ailment_model.dart';
import 'package:zim_herbs_repo/features/repository/ailments/data/models/body_part_model.dart';
import 'package:zim_herbs_repo/features/admin/ailment_management/presentation/body_parts_page.dart';
import 'add_edit_body_part_dialog.dart';

class AddEditAilmentDialog extends StatefulWidget {
  final AilmentModel? ailment;
  final Function(AilmentModel) onSave;

  const AddEditAilmentDialog({
    super.key,
    AilmentModel? ailment,
    AilmentModel? condition,
    required this.onSave,
  }) : ailment = ailment ?? condition;

  @override
  State<AddEditAilmentDialog> createState() => _AddEditAilmentDialogState();
}

class _AddEditAilmentDialogState extends State<AddEditAilmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _symptomsController;
  late TextEditingController _precautionsController;
  AilmentCategory _selectedAilmentCategory = AilmentCategory.heartBlood;

  List<BodyPartModel> _allBodyParts = [];
  final Set<String> _selectedBodyPartIds = {};
  bool _isLoadingBodyParts = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ailment?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.ailment?.description ?? '',
    );
    _symptomsController = TextEditingController(
      text: widget.ailment?.symptoms.join(', ') ?? '',
    );
    _precautionsController = TextEditingController(
      text: widget.ailment?.precautions.join(', ') ?? '',
    );
    if (widget.ailment != null) {
      _selectedAilmentCategory = widget.ailment!.ailmentCategory;
      _selectedBodyPartIds.addAll(
        widget.ailment!.bodyParts.map((bp) => bp.id),
      );
    }
    _loadBodyParts();
  }

  Future<void> _loadBodyParts() async {
    try {
      final dataSource = AilmentRemoteDataSource(Supabase.instance.client);
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

  Future<void> _addNewBodyPart() async {
    final newBp = await showDialog<BodyPartModel>(
      context: context,
      builder: (_) => const AddEditBodyPartDialog(),
    );
    if (newBp != null && mounted) {
      await _loadBodyParts();
      setState(() {
        _selectedBodyPartIds.add(newBp.id);
      });
    }
  }

  Future<void> _openManageBodyParts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BodyPartsPage(),
      ),
    );
    if (mounted) {
      await _loadBodyParts();
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
        widget.ailment == null ? 'Add Ailment' : 'Edit Ailment',
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
                    labelText: 'Ailment Name',
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
                      return 'Please enter an ailment name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AilmentCategory>(
                  initialValue: _selectedAilmentCategory,
                  decoration: InputDecoration(
                    labelText: 'Ailment Category',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: theme.colorScheme.onPrimary,
                    labelStyle: TextStyle(
                      fontSize: rs.labelFont,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  items:
                      AilmentCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(ailmentCategoryLabel(category)),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedAilmentCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Body Parts Affected section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Affected Body Parts',
                      style: TextStyle(
                        fontSize: rs.labelFont,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: _addNewBodyPart,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Part', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF106F74),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: _openManageBodyParts,
                          icon: const Icon(Icons.settings_outlined, size: 16),
                          tooltip: 'Manage All Body Parts',
                          color: const Color(0xFF106F74),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
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
                    labelText: 'Symptoms (comma-separated)',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: theme.colorScheme.onPrimary,
                    labelStyle: TextStyle(
                      fontSize: rs.labelFont,
                      color: theme.colorScheme.primary,
                    ),
                    helperText: 'e.g. Headache, Fever, Fatigue',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _precautionsController,
                  decoration: InputDecoration(
                    labelText: 'Precautions (comma-separated)',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: theme.colorScheme.onPrimary,
                    labelStyle: TextStyle(
                      fontSize: rs.labelFont,
                      color: theme.colorScheme.primary,
                    ),
                    helperText: 'e.g. Drink fluids, Rest, Avoid sunlight',
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
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: rs.bodyFont,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        FilledButton(
          onPressed: _saveAilment,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF106F74),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Save Ailment',
            style: TextStyle(
              fontSize: rs.bodyFont,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _saveAilment() {
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

      final newAilment = AilmentModel(
        id: widget.ailment?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        ailmentCategory: _selectedAilmentCategory,
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        symptoms: symptoms,
        precautions: precautions,
        bodyParts: selectedBodyParts,
      );

      widget.onSave(newAilment);
      Navigator.pop(context);
    }
  }
}

/// Backward-compatible alias for legacy AddEditConditionDialog
typedef AddEditConditionDialog = AddEditAilmentDialog;
