import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/repository/ailments/data/datasources/ailment_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/ailments/data/models/body_part_model.dart';

/// Modal dialog for adding or editing a Body Part record in the database.
class AddEditBodyPartDialog extends StatefulWidget {
  final BodyPartModel? bodyPart;
  final Future<void> Function(BodyPartModel)? onSave;

  const AddEditBodyPartDialog({
    super.key,
    this.bodyPart,
    this.onSave,
  });

  @override
  State<AddEditBodyPartDialog> createState() => _AddEditBodyPartDialogState();
}

class _AddEditBodyPartDialogState extends State<AddEditBodyPartDialog> {
  static const Color _conditionBlue = Color(0xFF106F74);
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameEnController;
  late TextEditingController _nameSnController;
  late TextEditingController _nameNdController;
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final bp = widget.bodyPart;
    _nameEnController = TextEditingController(text: bp?.nameEn ?? '');
    _nameSnController = TextEditingController(text: bp?.nameSn ?? '');
    _nameNdController = TextEditingController(text: bp?.nameNd ?? '');
    _codeController = TextEditingController(text: bp?.code ?? '');
    _descriptionController = TextEditingController(text: bp?.description ?? '');
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameSnController.dispose();
    _nameNdController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final isEdit = widget.bodyPart != null;
      final modelToSave = BodyPartModel(
        id: widget.bodyPart?.id ?? '',
        code: _codeController.text.trim().isEmpty
            ? null
            : _codeController.text.trim().toUpperCase(),
        nameEn: _nameEnController.text.trim(),
        nameSn: _nameSnController.text.trim().isEmpty
            ? null
            : _nameSnController.text.trim(),
        nameNd: _nameNdController.text.trim().isEmpty
            ? null
            : _nameNdController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        iconUrl: widget.bodyPart?.iconUrl,
      );

      BodyPartModel result;
      if (widget.onSave != null) {
        await widget.onSave!(modelToSave);
        result = modelToSave;
      } else {
        final dataSource = AilmentRemoteDataSource(Supabase.instance.client);
        if (isEdit) {
          result = await dataSource.updateBodyPart(modelToSave);
        } else {
          result = await dataSource.createBodyPart(modelToSave);
        }
      }

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final isEdit = widget.bodyPart != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _conditionBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.accessibility_new_rounded,
              color: _conditionBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEdit ? 'Edit Body Part' : 'Add New Body Part',
              style: TextStyle(
                fontSize: rs.titleFont * 1.1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // English name (Required)
                TextFormField(
                  controller: _nameEnController,
                  decoration: const InputDecoration(
                    labelText: 'English Anatomical Name *',
                    hintText: 'e.g. Liver, Kidneys, Heart',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title_rounded, size: 20),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter English anatomical name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Shona translation
                TextFormField(
                  controller: _nameSnController,
                  decoration: const InputDecoration(
                    labelText: 'Shona Name (Optional)',
                    hintText: 'e.g. Chiropa, Itsvo, Mwoyo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.translate_rounded, size: 20),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),

                // Ndebele translation
                TextFormField(
                  controller: _nameNdController,
                  decoration: const InputDecoration(
                    labelText: 'Ndebele Name (Optional)',
                    hintText: 'e.g. Isibindi, Izinso, Inhliziyo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.translate_rounded, size: 20),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),

                // Code / Identifier
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code / Key (Optional)',
                    hintText: 'e.g. LIVER, KIDNEYS, HEART',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag_rounded, size: 20),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 14),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description / Physiological Role (Optional)',
                    hintText: 'Anatomical functions or medical notes...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _handleSave,
          style: FilledButton.styleFrom(
            backgroundColor: _conditionBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: Text(isEdit ? 'Update Body Part' : 'Save Body Part'),
        ),
      ],
    );
  }
}
