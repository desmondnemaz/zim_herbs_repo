import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:zim_herbs_repo/features/herbs/data/herb_repository.dart';
import 'package:zim_herbs_repo/features/herbs/data/models.dart';
import 'package:flutter/foundation.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

class AddEditHerbPage extends StatefulWidget {
  final HerbModel? herb;

  const AddEditHerbPage({super.key, this.herb});

  @override
  State<AddEditHerbPage> createState() => _AddEditHerbPageState();
}

class _AddEditHerbPageState extends State<AddEditHerbPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameEnController;
  late TextEditingController _nameSnController;
  late TextEditingController _nameNdController;
  late TextEditingController _descriptionController;

  final List<XFile> _selectedImages = [];
  final List<Uint8List> _selectedImageBytes = [];
  bool _isSaving = false;
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

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
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

        // 2. Save Herb Record (Create or Update)
        if (widget.herb == null) {
          await _repository.createHerb(newHerb);
        } else {
          await _repository.updateHerb(newHerb);
        }

        // 3. Upload All Selected Images
        for (var i = 0; i < _selectedImages.length; i++) {
          try {
            final image = _selectedImages[i];
            final bytes = _selectedImageBytes[i];
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
              orderIndex: (widget.herb?.images.length ?? 0) + i,
            );

            await _repository.addHerbImage(herbImage);
          } catch (e) {
            debugPrint('Error handling herb image upload: $e');
          }
        }

        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate search update
        }
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
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.herb == null ? 'Add Herb' : 'Edit Herb',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.secondary,
        actions: [
          if (!_isSaving)
            IconButton(icon: const Icon(Icons.check), onPressed: _submit),
        ],
      ),
      body:
          _isSaving
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      Text(
                        "Herb Images",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: rs.titleFont,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Horizontal list of images
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // Existing Images
                            if (widget.herb != null)
                              ...widget.herb!.images.map(
                                (img) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      img.imageUrl,
                                      width: 120,
                                      height: 120,
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
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        _selectedImageBytes[entry.key],
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 12,
                                    top: 4,
                                    child: GestureDetector(
                                      onTap:
                                          () => _removeSelectedImage(entry.key),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
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

                            // Add Button
                            GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Add Photo",
                                      style: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: rs.labelFont,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form Fields
                      _buildTextField(
                        controller: _nameEnController,
                        label: 'Name (English)',
                        rs: rs,
                        validator:
                            (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _nameSnController,
                        label: 'Name (Shona)',
                        rs: rs,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _nameNdController,
                        label: 'Name (Ndebele)',
                        rs: rs,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        rs: rs,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'SAVE HERB',
                            style: TextStyle(
                              fontSize: rs.subtitleFont,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ResponsiveSize rs,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
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
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
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
      ),
      validator: validator,
    );
  }
}
