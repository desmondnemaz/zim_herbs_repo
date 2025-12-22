import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:zim_herbs_repo/features/herbs/data/herb_repository.dart';
import 'package:zim_herbs_repo/features/herbs/data/models.dart';
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

  final List<XFile> _selectedImages = [];
  final List<Uint8List> _selectedImageBytes = [];
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

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (var image in images) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImages.add(image);
          _selectedImageBytes.add(bytes);
        });
      }
    }
  }

  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _selectedImageBytes.removeAt(index);
    });
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
              // Image Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Images",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),

              // Horizontal list of images
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Existing Images (from database)
                    if (widget.herb != null)
                      ...widget.herb!.images.map(
                        (img) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              img.imageUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                    // Newly Selected Images
                    ..._selectedImages.asMap().entries.map(
                      (entry) => Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _selectedImageBytes[entry.key],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => _removeSelectedImage(entry.key),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Add Button
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Icon(
                          Icons.add_a_photo,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child:
              _isUploading
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
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
          return;
        }

        // 3. Upload All Selected Images
        for (var image in _selectedImages) {
          try {
            final bytes = await image.readAsBytes();
            final fileName =
                '${DateTime.now().millisecondsSinceEpoch}_${image.name}';

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
            debugPrint('Error handling herb image upload: $e');
            // Continue with other images even if one fails
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
