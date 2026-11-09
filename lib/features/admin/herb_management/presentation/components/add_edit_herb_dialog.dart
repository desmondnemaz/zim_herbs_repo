import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/utils/clipboard_image_service.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/datasources/herb_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/models/herb_model.dart';

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
  late TextEditingController _cautionController;
  late TextEditingController _sourceController;
  late TextEditingController _otherUsesNotesController;

  final List<XFile> _selectedImages = [];
  final List<Uint8List> _selectedImageBytes = [];
  late List<HerbImageModel> _existingImages;
  final List<String> _deletedImageIds = [];
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final HerbRemoteDataSource _repository =
      HerbRemoteDataSource(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _existingImages = List<HerbImageModel>.from(widget.herb?.images ?? []);
    _nameEnController = TextEditingController(text: widget.herb?.nameEn ?? '');
    _nameSnController = TextEditingController(text: widget.herb?.nameSn ?? '');
    _nameNdController = TextEditingController(text: widget.herb?.nameNd ?? '');
    _descriptionController = TextEditingController(
      text: widget.herb?.description ?? '',
    );
    _cautionController = TextEditingController(
      text: widget.herb?.caution ?? '',
    );
    _sourceController = TextEditingController(
      text: widget.herb?.source ?? '',
    );
    _otherUsesNotesController = TextEditingController(
      text: widget.herb?.otherUsesNotes ?? '',
    );
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameSnController.dispose();
    _nameNdController.dispose();
    _descriptionController.dispose();
    _cautionController.dispose();
    _sourceController.dispose();
    _otherUsesNotesController.dispose();
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

  void _removeExistingImage(int index) {
    setState(() {
      final removed = _existingImages.removeAt(index);
      _deletedImageIds.add(removed.id);
    });
  }

  Future<void> _pasteImageFromClipboard() async {
    final bytes = await ClipboardImageService.getClipboardImage();
    if (bytes != null) {
      final plantName = _nameEnController.text.trim().isNotEmpty
          ? _nameEnController.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')
          : (_nameSnController.text.trim().isNotEmpty
              ? _nameSnController.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')
              : 'herb');
      final xFile = ClipboardImageService.bytesToXFile(bytes, prefix: plantName);
      setState(() {
        _selectedImages.add(xFile);
        _selectedImageBytes.add(bytes);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Image pasted from clipboard!'),
              ],
            ),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No image found on clipboard. Copy an image or press Win+Shift+S first.',
                  ),
                ),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
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
              CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.keyV, control: true):
                      _pasteImageFromClipboard,
                  const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
                      _pasteImageFromClipboard,
                },
                child: Focus(
                  child: SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Existing Images (from database)
                        ..._existingImages.asMap().entries.map(
                          (entry) => Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    entry.value.imageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.broken_image_rounded,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 4,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => _removeExistingImage(entry.key),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
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

                        // Add Photo Button
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 26,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Photo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Paste Image Button
                        GestureDetector(
                          onTap: _pasteImageFromClipboard,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF5EB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.content_paste_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 26,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Paste',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '(Ctrl+V)',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: const Color(0xFF2E7D32).withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _cautionController,
                decoration: InputDecoration(
                  labelText: 'Caution / Warnings (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sourceController,
                decoration: InputDecoration(
                  labelText: 'Source / References (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _otherUsesNotesController,
                decoration: InputDecoration(
                  labelText: 'Other Uses & Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
          caution: _cautionController.text.trim().isEmpty
              ? null
              : _cautionController.text.trim(),
          source: _sourceController.text.trim().isEmpty
              ? null
              : _sourceController.text.trim(),
          otherUsesNotes: _otherUsesNotesController.text.trim().isEmpty
              ? null
              : _otherUsesNotesController.text.trim(),
          scientificName: widget.herb?.scientificName,
          family: widget.herb?.family,
          growthHabit: widget.herb?.growthHabit,
          partsUsed: widget.herb?.partsUsed ?? const [],
          placesFound: widget.herb?.placesFound,
          exoticStatus: widget.herb?.exoticStatus ?? 'Indigenous',
          validationStatus: widget.herb?.validationStatus,
          createdAt: widget.herb?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          images: _existingImages,
          remedies: widget.herb?.remedies ?? [],
        );

        // 2. Pass the herb to the parent to save (Create/Update Herb Record)
        try {
          await widget.onSave(newHerb);
        } catch (e) {
          debugPrint('Error saving herb record: $e');
          return;
        }

        // 3. Delete Any Removed Existing Images
        for (final imageId in _deletedImageIds) {
          try {
            await _repository.deleteHerbImage(imageId);
          } catch (e) {
            debugPrint('Error deleting removed herb image $imageId: $e');
          }
        }

        // 4. Upload All Selected Images
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
          showAppErrorSnackBar(
            context,
            failure: ErrorHandler.handle(e),
          );
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
