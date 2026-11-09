import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:uuid/uuid.dart';
import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/components/app_page_app_bar.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/utils/clipboard_image_service.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/datasources/herb_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/models/herb_model.dart';

class _OtherUseItemState {
  final String id;
  String category;
  late final TextEditingController descriptionController;
  final bool isExisting;
  bool isDeleted = false;

  _OtherUseItemState({
    required this.id,
    required this.category,
    required String description,
    required this.isExisting,
  }) {
    descriptionController = TextEditingController(text: description);
  }

  void dispose() {
    descriptionController.dispose();
  }
}

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
  late TextEditingController _scientificNameController;
  late TextEditingController _familyController;
  late TextEditingController _placesFoundController;
  late TextEditingController _partsUsedController;
  late TextEditingController _descriptionController;
  late TextEditingController _cautionController;
  late TextEditingController _sourceController;
  late TextEditingController _otherUsesNotesController;

  String? _growthHabit;
  String? _exoticStatus;

  final List<_OtherUseItemState> _otherUses = [];

  final List<XFile> _selectedImages = [];
  final List<Uint8List> _selectedImageBytes = [];
  late List<HerbImageModel> _existingImages;
  final List<String> _deletedImageIds = [];
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();
  final HerbRemoteDataSource _repository =
      HerbRemoteDataSource(Supabase.instance.client);
  bool _isApproved = true;

  bool _initializedStatus = false;

  static const List<String> _commonParts = [
    'Leaves',
    'Roots',
    'Bark',
    'Seeds',
    'Flowers',
    'Fruit',
    'Bulbs',
    'Twigs',
    'Sap',
    'Whole Plant',
  ];

  static const List<String> _growthHabitOptions = [
    'Shrub',
    'Tree',
    'Herb',
    'Climber',
    'Creeper',
    'Grass',
    'Fern',
    'Succulent',
  ];

  static const List<String> _exoticStatusOptions = [
    'Indigenous',
    'Introduced / Naturalized',
    'Exotic / Cultivated',
  ];

  static const List<Map<String, String>> _categoryOptions = [
    {'value': 'food_nutrition', 'label': 'Food & Nutrition'},
    {'value': 'construction_fencing', 'label': 'Construction & Fencing'},
    {'value': 'firewood', 'label': 'Firewood & Fuel'},
    {'value': 'cultural_spiritual', 'label': 'Cultural & Spiritual'},
    {'value': 'ritual', 'label': 'Ritual Uses'},
    {'value': 'crafts_tools', 'label': 'Crafts & Practical Tools'},
    {'value': 'veterinary', 'label': 'Veterinary & Animal Care'},
    {'value': 'other', 'label': 'Other Practical Use'},
  ];

  @override
  void initState() {
    super.initState();
    _existingImages = List<HerbImageModel>.from(widget.herb?.images ?? []);
    _nameEnController = TextEditingController(text: widget.herb?.nameEn ?? '');
    _nameSnController = TextEditingController(text: widget.herb?.nameSn ?? '');
    _nameNdController = TextEditingController(text: widget.herb?.nameNd ?? '');
    _scientificNameController =
        TextEditingController(text: widget.herb?.scientificName ?? '');
    _familyController = TextEditingController(text: widget.herb?.family ?? '');
    _placesFoundController =
        TextEditingController(text: widget.herb?.placesFound ?? '');
    _partsUsedController =
        TextEditingController(text: widget.herb?.partsUsed.join(', ') ?? '');
    _descriptionController =
        TextEditingController(text: widget.herb?.description ?? '');
    _cautionController =
        TextEditingController(text: widget.herb?.caution ?? '');
    _sourceController = TextEditingController(text: widget.herb?.source ?? '');
    _otherUsesNotesController =
        TextEditingController(text: widget.herb?.otherUsesNotes ?? '');

    _growthHabit = widget.herb?.growthHabit;
    _exoticStatus = widget.herb?.exoticStatus ?? 'Indigenous';

    if (widget.herb != null) {
      for (final use in widget.herb!.otherUses) {
        _otherUses.add(_OtherUseItemState(
          id: use.id,
          category: use.category,
          description: use.description,
          isExisting: true,
        ));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedStatus) {
      _initializedStatus = true;
      final authState = context.read<AuthCubit>().state;
      final canModerate =
          authState is Authenticated && authState.user.canModerate;
      _isApproved = widget.herb?.isApproved ?? (canModerate ? true : false);
    }
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameSnController.dispose();
    _nameNdController.dispose();
    _scientificNameController.dispose();
    _familyController.dispose();
    _placesFoundController.dispose();
    _partsUsedController.dispose();
    _descriptionController.dispose();
    _cautionController.dispose();
    _sourceController.dispose();
    _otherUsesNotesController.dispose();
    for (final item in _otherUses) {
      item.dispose();
    }
    super.dispose();
  }

  void _togglePart(String part) {
    final currentText = _partsUsedController.text;
    final parts = currentText
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.contains(part)) {
      parts.remove(part);
    } else {
      parts.add(part);
    }

    setState(() {
      _partsUsedController.text = parts.join(', ');
    });
  }

  void _addOtherUseField() {
    setState(() {
      _otherUses.add(_OtherUseItemState(
        id: const Uuid().v4(),
        category: 'food_nutrition',
        description: '',
        isExisting: false,
      ));
    });
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

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final herbId = widget.herb?.id ?? const Uuid().v4();
        final authState = context.read<AuthCubit>().state;
        final currentUserId = authState is Authenticated
            ? authState.user.id
            : Supabase.instance.client.auth.currentUser?.id;
        final canModerate =
            authState is Authenticated && authState.user.canModerate;
        final effectiveIsApproved =
            canModerate ? _isApproved : (widget.herb?.isApproved ?? false);

        final parts = _partsUsedController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        // 1. Create/Construct Herb Model
        var newHerb = HerbModel(
          id: herbId,
          nameEn: _nameEnController.text.trim(),
          nameSn: _nameSnController.text.trim().isEmpty
              ? null
              : _nameSnController.text.trim(),
          nameNd: _nameNdController.text.trim().isEmpty
              ? null
              : _nameNdController.text.trim(),
          scientificName: _scientificNameController.text.trim().isEmpty
              ? null
              : _scientificNameController.text.trim(),
          family: _familyController.text.trim().isEmpty
              ? null
              : _familyController.text.trim(),
          growthHabit: _growthHabit,
          partsUsed: parts,
          placesFound: _placesFoundController.text.trim().isEmpty
              ? null
              : _placesFoundController.text.trim(),
          exoticStatus: _exoticStatus,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          caution: _cautionController.text.trim().isEmpty
              ? null
              : _cautionController.text.trim(),
          source: _sourceController.text.trim().isEmpty
              ? null
              : _sourceController.text.trim(),
          otherUsesNotes: _otherUsesNotesController.text.trim().isEmpty
              ? null
              : _otherUsesNotesController.text.trim(),
          validationStatus: effectiveIsApproved
              ? RecordValidationStatus.published
              : (widget.herb?.validationStatus == RecordValidationStatus.published && !canModerate
                  ? RecordValidationStatus.underReview
                  : (widget.herb?.validationStatus ?? RecordValidationStatus.submitted)),
          createdAt: widget.herb?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy:
              widget.herb == null ? currentUserId : widget.herb?.createdBy,
          updatedBy: currentUserId,
          verifiedBy: effectiveIsApproved
              ? (widget.herb?.verifiedBy ?? currentUserId)
              : null,
          verifiedAt: effectiveIsApproved
              ? (widget.herb?.verifiedAt ?? DateTime.now())
              : null,
          moderationNotes: widget.herb?.moderationNotes,
          images: _existingImages,
          remedies: widget.herb?.remedies ?? [],
        );

        // 2. Save Herb Record (Create or Update)
        if (widget.herb == null) {
          await _repository.createHerb(newHerb);
        } else {
          await _repository.updateHerb(newHerb);
        }

        // 3. Save Non-Medicinal Other Uses
        for (final item in _otherUses) {
          if (item.isDeleted && item.isExisting) {
            try {
              await _repository.deleteHerbOtherUse(item.id);
            } catch (e) {
              debugPrint('Error deleting other use ${item.id}: $e');
            }
          } else if (!item.isDeleted &&
              item.descriptionController.text.trim().isNotEmpty) {
            if (!item.isExisting) {
              try {
                await _repository.addHerbOtherUse({
                  'id': item.id,
                  'herb_id': herbId,
                  'category': item.category,
                  'description': item.descriptionController.text.trim(),
                  'created_by': currentUserId,
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                });
              } catch (e) {
                debugPrint('Error adding other use ${item.id}: $e');
              }
            }
          }
        }

        // 4. Delete Any Removed Existing Images
        for (final imageId in _deletedImageIds) {
          try {
            await _repository.deleteHerbImage(imageId);
          } catch (e) {
            debugPrint('Error deleting removed herb image $imageId: $e');
          }
        }

        // 5. Upload All Selected/Pasted Images
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
          Navigator.pop(context, true);
        }
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
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final theme = Theme.of(context);
    final currentParts = _partsUsedController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    return Scaffold(
      appBar: AppPageAppBar(
        title: widget.herb == null ? 'Add Herb' : 'Edit Herb',
        actions: [
          if (!_isSaving)
            IconButton(
              icon: const Icon(Icons.check_rounded),
              tooltip: 'Save Herb',
              onPressed: _submit,
            ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Herb Images
                    _buildSectionHeader(
                      icon: Icons.photo_library_rounded,
                      title: 'Herb Photos',
                      rs: rs,
                    ),
                    const SizedBox(height: 12),
                    CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.keyV, control: true):
                            _pasteImageFromClipboard,
                        const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
                            _pasteImageFromClipboard,
                      },
                      child: Focus(
                        child: SizedBox(
                          height: 124,
                          child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._existingImages.asMap().entries.map(
                            (entry) => Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      entry.value.imageUrl,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 120,
                                        height: 120,
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
                                  right: 14,
                                  top: 4,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _removeExistingImage(entry.key),
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
                          ..._selectedImages.asMap().entries.map(
                                (entry) => Stack(
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 10.0),
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
                                      right: 14,
                                      top: 4,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _removeSelectedImage(entry.key),
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
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 30,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Add Photo',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: rs.labelFont,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _pasteImageFromClipboard,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF5EB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.45),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.content_paste_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 30,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Paste Image',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: rs.labelFont,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '(Ctrl+V)',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                                      fontSize: 10.5,
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
                const SizedBox(height: 28),

                    // Section 2: Vernacular & Common Names
                    _buildSectionHeader(
                      icon: Icons.translate_rounded,
                      title: 'Vernacular & Common Names',
                      rs: rs,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _nameEnController,
                      label: 'Common / English Name *',
                      rs: rs,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _nameSnController,
                            label: 'Shona Name',
                            rs: rs,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _nameNdController,
                            label: 'Ndebele Name',
                            rs: rs,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Section 3: Botanical Profile
                    _buildSectionHeader(
                      icon: Icons.eco_rounded,
                      title: 'Botanical & Ecological Profile',
                      rs: rs,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _scientificNameController,
                            label: 'Scientific Name (e.g. Lippia javanica)',
                            rs: rs,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _familyController,
                            label: 'Botanical Family (e.g. Verbenaceae)',
                            rs: rs,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _growthHabit,
                            decoration: _dropdownDecoration('Growth Habit', rs),
                            dropdownColor: Colors.white,
                            items: _growthHabitOptions
                                .map((h) => DropdownMenuItem(
                                      value: h,
                                      child: Text(h),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _growthHabit = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _exoticStatus,
                            decoration:
                                _dropdownDecoration('Exotic / Native Status', rs),
                            dropdownColor: Colors.white,
                            items: _exoticStatusOptions
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _exoticStatus = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _placesFoundController,
                      label: 'Places Found (Habitat & Distribution)',
                      rs: rs,
                      hint:
                          'e.g. Open grasslands, rocky slopes, Miombo woodlands across Zimbabwe',
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _partsUsedController,
                      label: 'Parts Used (Comma separated)',
                      rs: rs,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _commonParts.map((part) {
                        final isSelected = currentParts.contains(part);
                        return FilterChip(
                          label: Text(
                            part,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF2E7D32),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF2E7D32),
                          checkmarkColor: Colors.white,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade300,
                          ),
                          onSelected: (_) => _togglePart(part),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // Section 4: Non-Medicinal Traditional Uses
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.interests_rounded,
                          title: 'Other Traditional Uses',
                          rs: rs,
                        ),
                        TextButton.icon(
                          onPressed: _addOtherUseField,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              size: 18),
                          label: const Text(
                            'Add Use',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Non-medicinal uses (Food, construction, firewood, cultural & spiritual practices, ritual, tools).',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_otherUses.where((u) => !u.isDeleted).isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 20,
                                color: Colors.grey.shade600),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No other traditional uses added yet. Click "Add Use" to record food, firewood, or cultural uses.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._otherUses.map((item) {
                        if (item.isDeleted) return const SizedBox.shrink();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: item.category,
                                        decoration: _dropdownDecoration(
                                            'Use Category', rs),
                                        dropdownColor: Colors.white,
                                        items: _categoryOptions
                                            .map((c) => DropdownMenuItem(
                                                  value: c['value'],
                                                  child: Text(c['label']!),
                                                ))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => item.category = val);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Remove',
                                      onPressed: () {
                                        setState(() {
                                          item.isDeleted = true;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: item.descriptionController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    labelText: 'Description of Use',
                                    hintText:
                                        'Describe how this plant is used for this purpose...',
                                    labelStyle: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: rs.labelFont,
                                    ),
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: rs.labelFont,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 28),

                    // Section 5: General Description
                    _buildSectionHeader(
                      icon: Icons.description_rounded,
                      title: 'General Botanical Description',
                      rs: rs,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      rs: rs,
                      maxLines: 4,
                      hint:
                          'Aromatic woody shrub, dense flowering clusters, ecological context...',
                    ),
                    const SizedBox(height: 28),

                    // Section 5b: Safety Precautions, Sources & Notes
                    _buildSectionHeader(
                      icon: Icons.health_and_safety_rounded,
                      title: 'Safety, Citations & General Notes',
                      rs: rs,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _cautionController,
                      label: 'Caution / Warnings (Optional)',
                      rs: rs,
                      maxLines: 3,
                      hint:
                          'Toxicity warnings, contraindications, side effects, precautions during pregnancy or high dosages...',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _sourceController,
                      label: 'Source / References (Optional)',
                      rs: rs,
                      maxLines: 2,
                      hint:
                          'Literature citations, botanical monographs, research papers, or traditional community sources...',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _otherUsesNotesController,
                      label: 'Other Uses & Notes (Optional)',
                      rs: rs,
                      maxLines: 3,
                      hint:
                          'General practical uses, preparation notes, traditional knowledge context...',
                    ),
                    const SizedBox(height: 28),

                    // Section 6: Moderation & Verification
                    Builder(
                      builder: (context) {
                        final authState = context.watch<AuthCubit>().state;
                        final canModerate = authState is Authenticated &&
                            authState.user.canModerate;

                        if (canModerate) {
                          return Material(
                            color: _isApproved
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFF8E1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _isApproved
                                    ? Colors.green.shade400
                                    : Colors.amber.shade500,
                              ),
                            ),
                            child: SwitchListTile(
                              value: _isApproved,
                              activeThumbColor: theme.colorScheme.primary,
                              title: Text(
                                _isApproved
                                    ? 'Verified Herb'
                                    : 'Unverified (Pending Review)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isApproved
                                      ? Colors.green.shade900
                                      : Colors.amber.shade900,
                                ),
                              ),
                              subtitle: Text(
                                _isApproved
                                    ? 'This herb is verified by moderators and visible to all users.'
                                    : 'This herb is unverified and pending moderator review.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isApproved
                                      ? Colors.green.shade800
                                      : Colors.amber.shade800,
                                ),
                              ),
                              secondary: Icon(
                                _isApproved
                                    ? Icons.verified_user_rounded
                                    : Icons.pending_actions_rounded,
                                color: _isApproved
                                    ? Colors.green.shade700
                                    : Colors.amber.shade800,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _isApproved = val;
                                });
                              },
                            ),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _isApproved
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isApproved
                                  ? Colors.green.shade400
                                  : Colors.amber.shade500,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isApproved
                                    ? Icons.verified_user_rounded
                                    : Icons.pending_actions_rounded,
                                color: _isApproved
                                    ? Colors.green.shade700
                                    : Colors.amber.shade800,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isApproved
                                          ? 'Verified Submission'
                                          : 'Pending Moderator Review',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _isApproved
                                            ? Colors.green.shade900
                                            : Colors.amber.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isApproved
                                          ? 'This herb has been verified by moderators.'
                                          : 'Your herb contribution will be submitted for review and will be visible under "My Creations" on your dashboard.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _isApproved
                                            ? Colors.green.shade800
                                            : Colors.amber.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 36),

                    // Section 7: Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(
                          widget.herb == null ? 'ADD HERB' : 'SAVE CHANGES',
                          style: TextStyle(
                            fontSize: rs.subtitleFont,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required ResponsiveSize rs,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: rs.titleFont,
            color: const Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration(String label, ResponsiveSize rs) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
        fontSize: rs.labelFont,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ResponsiveSize rs,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: rs.labelFont,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: rs.labelFont,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }
}
