import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:zim_herbs_repo/features/herbs/data/herb_repository.dart';
import 'package:zim_herbs_repo/features/herbs/data/models.dart';
import 'package:zim_herbs_repo/theme/light_mode.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AddEditHerbDialog extends StatefulWidget {
  final HerbModel? herb;
  final Function(HerbModel) onSave;

  const AddEditHerbDialog({super.key, this.herb, required this.onSave});

  @override
  State<AddEditHerbDialog> createState() => _AddEditHerbDialogState();
}

class _AddEditHerbDialogState extends State<AddEditHerbDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameEnController;
  late TextEditingController _nameSnController;
  late TextEditingController _nameNdController;
  late TextEditingController _descriptionController;

  XFile? _selectedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final HerbRepository _repository = HerbRepository();

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(text: widget.herb?.nameEn ?? '');
    _nameSnController = TextEditingController(text: widget.herb?.nameSn ?? '');
    _nameNdController = TextEditingController(text: widget.herb?.nameNd ?? '');
    _descriptionController = TextEditingController(
      text: widget.herb?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameSnController.dispose();
    _nameNdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.herb == null ? 'Add Herb' : 'Edit Herb'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                    image:
                        _selectedImage != null
                            ? DecorationImage(
                              image:
                                  kIsWeb
                                      ? NetworkImage(_selectedImage!.path)
                                      : FileImage(File(_selectedImage!.path))
                                          as ImageProvider,
                              fit: BoxFit.cover,
                            )
                            : (widget.herb?.primaryImageUrl != null
                                ? DecorationImage(
                                  image: NetworkImage(
                                    widget.herb!.primaryImageUrl!,
                                  ),
                                  fit: BoxFit.cover,
                                )
                                : null),
                  ),
                  child:
                      _selectedImage == null &&
                              widget.herb?.primaryImageUrl == null
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Colors.grey[600],
                                ),
                                Text(
                                  "Tap to add image",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameEnController,
                decoration: InputDecoration(
                  labelText: 'Name (English)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter English name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameSnController,
                decoration: InputDecoration(
                  labelText: 'Name (Shona)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameNdController,
                decoration: InputDecoration(
                  labelText: 'Name (Ndebele)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: pharmacyTheme.colorScheme.primary,
            foregroundColor: pharmacyTheme.colorScheme.onPrimary,
          ),
          child:
              _isUploading
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: pharmacyTheme.colorScheme.onPrimary,
                    ),
                  )
                  : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploading = true;
      });

      try {
        final herbId = widget.herb?.id ?? const Uuid().v4();

        // 1. Create/Construct Herb Model
        var newHerb = HerbModel(
          id: herbId,
          nameEn: _nameEnController.text,
          nameSn:
              _nameSnController.text.isEmpty ? null : _nameSnController.text,
          nameNd:
              _nameNdController.text.isEmpty ? null : _nameNdController.text,
          description:
              _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
          createdAt: widget.herb?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          images: widget.herb?.images ?? [],
          treatments: widget.herb?.treatments ?? [],
        );

        // 2. Pass the herb to the parent to save (Create/Update Herb Record)
        try {
          await widget.onSave(newHerb);
        } catch (e) {
          debugPrint('Error saving herb record: $e');
          // If herb save fails, we stop here as image needs a valid herb record
          return;
        }

        // 3. Upload Image if selected
        if (_selectedImage != null) {
          try {
            final bytes = await _selectedImage!.readAsBytes();
            final fileName =
                '${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.name}';

            final imageUrl = await _repository.uploadHerbImage(
              herbId,
              fileName,
              bytes,
            );

            // Create Image Record
            final herbImage = HerbImageModel(
              id: const Uuid().v4(),
              herbId: herbId,
              imageUrl: imageUrl,
              orderIndex: 0,
            );

            await _repository.addHerbImage(herbImage);
          } catch (e) {
            debugPrint('Error handling herb image: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Herb saved, but image upload failed: $e'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            // We don't return here because the herb itself was saved successfully
          }
        }

        if (mounted) Navigator.pop(context);
      } catch (e) {
        debugPrint('Unexpected error in _submit: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }
}
