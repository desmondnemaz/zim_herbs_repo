import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/admin/herb_management/data/services/herb_spreadsheet_service.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/datasources/herb_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/repositories/herb_repository_impl.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/repositories/herb_repository.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/cubit/herb_cubit.dart';

enum _ReviewFilter { all, valid, issues }

/// Full-page stepped Excel/CSV import wizard with explicit import rules
/// and responsive mobile/desktop layouts (cards on desktop, ListTiles on mobile).
class HerbImportPage extends StatefulWidget {
  final VoidCallback? onBack;

  const HerbImportPage({super.key, this.onBack});

  @override
  State<HerbImportPage> createState() => _HerbImportPageState();
}

class _HerbImportPageState extends State<HerbImportPage> {
  static const Color _primaryGreen = Color(0xFF2E7D32);

  int _currentStep = 0; // 0: Rules, 1: Template, 2: Upload, 3: Review & Import
  String? _selectedFileName;
  List<ParsedHerbImportRow> _parsedRows = [];
  _ReviewFilter _reviewFilter = _ReviewFilter.all;

  bool _isLoading = false;
  bool _isImporting = false;
  bool _importCompleted = false;
  double _importProgress = 0.0;
  String _statusMessage = '';
  int _importedSuccessCount = 0;
  int _importedErrorCount = 0;
  int _importedOtherUsesCount = 0;

  static const List<_ImportRuleSpec> _importRules = [
    _ImportRuleSpec(
      number: 'Rule 1',
      title: 'Supported File Formats (.xlsx & .csv)',
      description:
          'Upload a Microsoft Excel workbook (.xlsx) or a UTF-8 Comma-Separated Values (.csv) file. The importer reads the first worksheet automatically.',
      icon: Icons.insert_drive_file_outlined,
      isRequired: true,
    ),
    _ImportRuleSpec(
      number: 'Rule 2',
      title: 'Keep Row 1 as Column Headers',
      description:
          'Row 1 must contain the column header names (e.g. common_name_en, scientific_name). Plant records must start on Row 2.',
      icon: Icons.table_rows_outlined,
      isRequired: true,
    ),
    _ImportRuleSpec(
      number: 'Rule 3',
      title: 'Common English Name is Mandatory',
      description:
          'Every row must have common_name_en filled in. Any row missing a Common Name will fail validation and be skipped safely.',
      icon: Icons.verified_outlined,
      isRequired: true,
    ),
    _ImportRuleSpec(
      number: 'Rule 4',
      title: 'Comma-Separated Plant Parts',
      description:
          'In the parts_used column, separate multiple parts with commas, slashes, or semicolons (for example: Leaves, Roots, Bark).',
      icon: Icons.local_offer_outlined,
      isRequired: false,
    ),
    _ImportRuleSpec(
      number: 'Rule 5',
      title: 'Origin / Exotic Status Values',
      description:
          'Use "Indigenous", "Introduced / Naturalized", or "Exotic / Cultivated" in exotic_status. Defaults to Indigenous if left blank.',
      icon: Icons.public_rounded,
      isRequired: false,
    ),
    _ImportRuleSpec(
      number: 'Rule 6',
      title: 'Traditional Non-Medicinal Uses',
      description:
          'Any text entered in food_nutrition, construction_fencing, firewood, cultural_spiritual, ritual, crafts_tools, or other_uses is automatically linked to the herb.',
      icon: Icons.auto_awesome_mosaic_outlined,
      isRequired: false,
    ),
  ];

  static const List<_ColumnRuleSpec> _columnSpecs = [
    _ColumnRuleSpec(
      keyName: 'common_name_en',
      label: 'Common Name (English)',
      required: true,
      example: 'Fever Tea (Zumbani)',
    ),
    _ColumnRuleSpec(
      keyName: 'scientific_name',
      label: 'Scientific Name',
      required: false,
      example: 'Lippia javanica',
    ),
    _ColumnRuleSpec(
      keyName: 'name_shona',
      label: 'Shona Name',
      required: false,
      example: 'Zumbani',
    ),
    _ColumnRuleSpec(
      keyName: 'name_ndebele',
      label: 'Ndebele Name',
      required: false,
      example: 'Insuzwane',
    ),
    _ColumnRuleSpec(
      keyName: 'family',
      label: 'Botanical Family',
      required: false,
      example: 'Verbenaceae',
    ),
    _ColumnRuleSpec(
      keyName: 'growth_habit',
      label: 'Growth Habit',
      required: false,
      example: 'Shrub, Tree, Herb, Climber',
    ),
    _ColumnRuleSpec(
      keyName: 'parts_used',
      label: 'Parts Used',
      required: false,
      example: 'Leaves, Twigs, Roots',
    ),
    _ColumnRuleSpec(
      keyName: 'places_found',
      label: 'Where Found',
      required: false,
      example: 'Open grasslands & rocky slopes',
    ),
    _ColumnRuleSpec(
      keyName: 'exotic_status',
      label: 'Exotic Status',
      required: false,
      example: 'Indigenous',
    ),
    _ColumnRuleSpec(
      keyName: 'description',
      label: 'Botanical Description',
      required: false,
      example: 'Aromatic woody shrub...',
    ),
    _ColumnRuleSpec(
      keyName: 'caution',
      label: 'Caution / Warnings',
      required: false,
      example: 'Avoid high doses during early pregnancy',
    ),
    _ColumnRuleSpec(
      keyName: 'source',
      label: 'Source / References',
      required: false,
      example: 'Flora of Zimbabwe; Ethnobotanical survey',
    ),
    _ColumnRuleSpec(
      keyName: 'other_uses_notes',
      label: 'Other Uses & Notes',
      required: false,
      example: 'Used for traditional steam bath & granary pest control',
    ),
    _ColumnRuleSpec(
      keyName: 'food_nutrition',
      label: 'Food & Nutrition',
      required: false,
      example: 'Herbal tea beverage',
    ),
    _ColumnRuleSpec(
      keyName: 'construction_fencing',
      label: 'Construction & Fencing',
      required: false,
      example: 'Granary pest repellent branches',
    ),
    _ColumnRuleSpec(
      keyName: 'firewood',
      label: 'Firewood & Fuel',
      required: false,
      example: 'Dry stems used for kindling',
    ),
    _ColumnRuleSpec(
      keyName: 'cultural_spiritual',
      label: 'Cultural & Spiritual',
      required: false,
      example: 'Purification steam wash',
    ),
    _ColumnRuleSpec(
      keyName: 'ritual',
      label: 'Ritual Uses',
      required: false,
      example: 'Cleansing ceremonies',
    ),
    _ColumnRuleSpec(
      keyName: 'crafts_tools',
      label: 'Crafts & Practical Tools',
      required: false,
      example: 'Natural insect repellent',
    ),
    _ColumnRuleSpec(
      keyName: 'other_uses',
      label: 'Other Uses',
      required: false,
      example: 'Essential oil extraction',
    ),
  ];

  Future<void> _downloadTemplate({bool asExcel = true}) async {
    try {
      final Uint8List bytes = asExcel
          ? HerbSpreadsheetService.generateStandardExcelTemplate()
          : HerbSpreadsheetService.generateStandardTemplateBytes();
      final String fileName = asExcel
          ? 'zim_herbs_standard_template.xlsx'
          : 'zim_herbs_standard_template.csv';

      bool saved = false;

      try {
        final result = await FilePickerPlatform.instance.saveFile(
          dialogTitle: 'Save Herbs Template',
          fileName: fileName,
          bytes: bytes,
          mimeType: asExcel
              ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
              : 'text/csv',
        );
        if (result != null) saved = true;
      } catch (_) {}

      if (!saved) {
        try {
          await Printing.sharePdf(bytes: bytes, filename: fileName);
          saved = true;
        } catch (printingError) {
          if (!kIsWeb &&
              (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
            final userHome = Platform.environment['USERPROFILE'] ??
                Platform.environment['HOME'];
            if (userHome != null) {
              final downloadsDir = Directory('$userHome\\Downloads');
              if (await downloadsDir.exists()) {
                final targetFile = File('${downloadsDir.path}\\$fileName');
                await targetFile.writeAsBytes(bytes);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Saved to Downloads: $fileName'),
                      backgroundColor: _primaryGreen,
                    ),
                  );
                }
                return;
              }
            }
          }
          throw Exception('Unable to save template: $printingError');
        }
      }

      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template downloaded: $fileName'),
            backgroundColor: _primaryGreen,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to download template: $e');
    }
  }

  Future<void> _pickAndParseFile() async {
    try {
      final authState = context.read<AuthCubit>().state;
      final currentUserId =
          authState is Authenticated ? authState.user.id : null;

      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
      );

      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        _showError('Could not read the selected file.');
        return;
      }

      setState(() {
        _isLoading = true;
        _selectedFileName = file.name;
        _importCompleted = false;
      });

      final rows = HerbSpreadsheetService.parseSpreadsheet(
        bytes: bytes,
        fileName: file.name,
        currentUserId: currentUserId,
      );

      setState(() {
        _parsedRows = rows;
        _isLoading = false;
        _reviewFilter = _ReviewFilter.all;
        if (rows.isNotEmpty) {
          _currentStep = 3; // Advance to Step 4: Review & Import
        } else {
          _showError('No herb rows found in ${file.name}.');
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to read file: $e');
    }
  }

  Future<void> _executeImport() async {
    final validRows = _parsedRows.where((r) => r.isValid).toList();
    if (validRows.isEmpty) {
      _showError('No valid rows available to import.');
      return;
    }

    setState(() {
      _isImporting = true;
      _importCompleted = false;
      _importProgress = 0.0;
      _importedSuccessCount = 0;
      _importedErrorCount = 0;
      _importedOtherUsesCount = 0;
      _statusMessage = 'Starting import of ${validRows.length} herbs...';
    });

    final HerbRepository repo;
    try {
      repo = context.read<HerbRepository>();
    } catch (_) {
      final client = Supabase.instance.client;
      final dataSource = HerbRemoteDataSource(client);
      repo = HerbRepositoryImpl(dataSource);
    }

    final authState = context.read<AuthCubit>().state;
    final currentUserId =
        authState is Authenticated ? authState.user.id : null;
    final canModerate =
        authState is Authenticated && authState.user.canModerate;

    int successCount = 0;
    int errorCount = 0;
    int usesCount = 0;

    try {
      for (int i = 0; i < validRows.length; i++) {
        final row = validRows[i];
        try {
          final rawEntity = row.herb.toEntity();
          final entityToSave = Herb(
            id: rawEntity.id,
            nameEn: rawEntity.nameEn,
            nameSn: rawEntity.nameSn,
            nameNd: rawEntity.nameNd,
            scientificName: rawEntity.scientificName,
            family: rawEntity.family,
            growthHabit: rawEntity.growthHabit,
            partsUsed: rawEntity.partsUsed,
            placesFound: rawEntity.placesFound,
            exoticStatus: rawEntity.exoticStatus,
            description: rawEntity.description,
            caution: rawEntity.caution,
            source: rawEntity.source,
            otherUsesNotes: rawEntity.otherUsesNotes,
            validationStatus: canModerate
                ? RecordValidationStatus.published
                : RecordValidationStatus.submitted,
            images: rawEntity.images,
            otherUses: rawEntity.otherUses,
            createdAt: rawEntity.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: currentUserId ?? rawEntity.createdBy,
            updatedBy: currentUserId,
            verifiedBy: canModerate ? currentUserId : null,
            verifiedAt: canModerate ? DateTime.now() : null,
          );

          final createdHerb = await repo.createHerb(entityToSave);

          for (final otherUse in row.otherUses) {
            final enrichedUse =
                otherUse.toEntity().copyWith(herbId: createdHerb.id);
            await repo.addHerbOtherUse(enrichedUse);
            usesCount++;
          }
          successCount++;
        } catch (e, stackTrace) {
          debugPrint('[HerbImportPage] Error importing row $i (${row.herb.displayName}): $e\n$stackTrace');
          errorCount++;
        }

        if (mounted) {
          setState(() {
            _importProgress = (i + 1) / validRows.length;
            _importedSuccessCount = successCount;
            _importedErrorCount = errorCount;
            _importedOtherUsesCount = usesCount;
            _statusMessage =
                'Imported ${i + 1} of ${validRows.length} herbs ($successCount saved)';
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[HerbImportPage] Fatal import loop error: $e\n$stackTrace');
      _showError('Import halted: $e');
    } finally {
      if (mounted) {
        context.read<HerbCubit>().loadHerbs();
        setState(() {
          _isImporting = false;
          _importCompleted = true;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, _importCompleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F2),
      appBar: isDesktop
          ? null
          : AppPageAppBar(
              title: 'Import Excel / CSV',
              onBack: _isImporting ? null : _handleBack,
            ),
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Excel & CSV Herb Import',
              subtitle:
                  'Guided 4-step import process with validation rules',
              icon: Icons.table_chart_rounded,
              onBack: _isImporting ? null : _handleBack,
            ),

            // 4-Step Responsive Stepper Bar
            _buildStepperHeader(isMobile),

            // Active Step Page Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(rs.defaultPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: _buildStepPageContent(isMobile),
                  ),
                ),
              ),
            ),

            // Bottom Navigation Bar
            _buildBottomStepControls(rs, isMobile),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // RESPONSIVE 4-STEP BAR
  // ===========================================================================

  Widget _buildStepperHeader(bool isMobile) {
    const steps = [
      (num: '1', short: 'Rules', full: '1. Import Rules'),
      (num: '2', short: 'Template', full: '2. Template'),
      (num: '3', short: 'Upload', full: '3. Upload File'),
      (num: '4', short: 'Import', full: '4. Review & Import'),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Row(
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final isActive = _currentStep == index;
              final isDone = _currentStep > index ||
                  (index == 3 && _importCompleted);
              final canTap = !_isImporting &&
                  (index <= 2 || _parsedRows.isNotEmpty);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: canTap
                        ? () => setState(() => _currentStep = index)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: isMobile ? 4 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? _primaryGreen
                            : isDone
                                ? const Color(0xFFEAF5EB)
                                : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isDone && !isActive) ...[
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: _primaryGreen,
                            ),
                            const SizedBox(width: 4),
                          ] else ...[
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : const Color(0xFFCBD5E1),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                step.num,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Flexible(
                            child: Text(
                              isMobile ? step.short : step.full,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isMobile ? 11.5 : 13,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? Colors.white
                                    : isDone
                                        ? const Color(0xFF1B5E20)
                                        : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildStepPageContent(bool isMobile) {
    switch (_currentStep) {
      case 0:
        return _buildStep1RulesPage(isMobile);
      case 1:
        return _buildStep2TemplatePage(isMobile);
      case 2:
        return _buildStep3UploadPage(isMobile);
      case 3:
        return _buildStep4ReviewPage(isMobile);
      default:
        return _buildStep1RulesPage(isMobile);
    }
  }

  // ===========================================================================
  // STEP 1: IMPORT RULES PAGE (CARDS ON DESKTOP, LISTTILES ON MOBILE)
  // ===========================================================================

  Widget _buildStep1RulesPage(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepBanner(
          stepBadge: 'STEP 1 OF 4',
          title: 'Spreadsheet Import Rules',
          subtitle:
              'Please review these 6 rules before uploading your Excel or CSV file so all records validate cleanly.',
          icon: Icons.rule_rounded,
        ),
        const SizedBox(height: 16),
        if (isMobile)
          Material(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _importRules.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final rule = _importRules[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: rule.isRequired
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFEAF5EB),
                    child: Icon(
                      rule.icon,
                      size: 20,
                      color: rule.isRequired
                          ? const Color(0xFFDC2626)
                          : _primaryGreen,
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          rule.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _RuleBadge(isRequired: rule.isRequired),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      rule.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisExtent: 170,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: _importRules.length,
            itemBuilder: (context, index) {
              final rule = _importRules[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: rule.isRequired
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFEAF5EB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              rule.icon,
                              size: 20,
                              color: rule.isRequired
                                  ? const Color(0xFFDC2626)
                                  : _primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            rule.number,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const Spacer(),
                          _RuleBadge(isRequired: rule.isRequired),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        rule.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          rule.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ===========================================================================
  // STEP 2: DOWNLOAD TEMPLATE & COLUMN RULES PAGE
  // ===========================================================================

  Widget _buildStep2TemplatePage(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepBanner(
          stepBadge: 'STEP 2 OF 4',
          title: 'Download Standard Template',
          subtitle:
              'Download the pre-formatted Excel (.xlsx) or CSV template. It includes all 17 supported column headers and a sample row.',
          icon: Icons.file_download_outlined,
        ),
        const SizedBox(height: 16),

        // Download buttons card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: isMobile
              ? Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _downloadTemplate(asExcel: true),
                        icon: const Icon(Icons.download_rounded, size: 17),
                        label: const Text('Excel'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadTemplate(asExcel: false),
                        icon: const Icon(Icons.download_rounded, size: 17),
                        label: const Text('CSV'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Official Zim Herbs Spreadsheet Templates',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Choose Excel (.xlsx) for Microsoft Excel/Google Sheets or UTF-8 CSV.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: () => _downloadTemplate(asExcel: true),
                      icon: const Icon(Icons.download_rounded, size: 17),
                      label: const Text('Excel'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => _downloadTemplate(asExcel: false),
                      icon: const Icon(Icons.download_rounded, size: 17),
                      label: const Text('CSV'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 18),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Supported Columns (1 Required, 16 Optional)',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Mobile: ListTiles | Desktop: Grid Cards
        if (isMobile)
          Material(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _columnSpecs.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final col = _columnSpecs[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          col.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _RuleBadge(isRequired: col.required),
                    ],
                  ),
                  subtitle: Text(
                    'Header: ${col.keyName} • e.g. "${col.example}"',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                );
              },
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 340,
              mainAxisExtent: 104,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _columnSpecs.length,
            itemBuilder: (context, index) {
              final col = _columnSpecs[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              col.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          _RuleBadge(isRequired: col.required),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        col.keyName,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'e.g. ${col.example}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ===========================================================================
  // STEP 3: UPLOAD FILE PAGE
  // ===========================================================================

  Widget _buildStep3UploadPage(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepBanner(
          stepBadge: 'STEP 3 OF 4',
          title: 'Select & Upload Spreadsheet',
          subtitle:
              'Choose your .xlsx or .csv file. Each row will be checked against the import rules before anything is saved.',
          icon: Icons.upload_file_rounded,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _isLoading ? null : _pickAndParseFile,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isMobile ? 28 : 44,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _primaryGreen.withValues(alpha: 0.45),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                if (_isLoading) ...[
                  const CircularProgressIndicator(color: _primaryGreen),
                  const SizedBox(height: 14),
                  const Text('Validating spreadsheet rows...'),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF5EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload_rounded,
                      size: 40,
                      color: _primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _selectedFileName ?? 'Tap to Select .xlsx or .csv File',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Supports Excel (.xlsx) and CSV (.csv) files',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _pickAndParseFile,
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: Text(
                      _selectedFileName == null
                          ? 'Browse Device Files'
                          : 'Choose Another File',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 4: REVIEW & IMPORT PAGE (CARDS ON DESKTOP, LISTTILES ON MOBILE)
  // ===========================================================================

  Widget _buildStep4ReviewPage(bool isMobile) {
    final totalCount = _parsedRows.length;
    final validCount = _parsedRows.where((r) => r.isValid).length;
    final issueCount =
        _parsedRows.where((r) => !r.isValid || r.warnings.isNotEmpty).length;

    final filteredRows = _parsedRows.where((r) {
      switch (_reviewFilter) {
        case _ReviewFilter.all:
          return true;
        case _ReviewFilter.valid:
          return r.isValid;
        case _ReviewFilter.issues:
          return !r.isValid || r.warnings.isNotEmpty;
      }
    }).toList();

    if (_importCompleted) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.verified_rounded,
              size: 56,
              color: _primaryGreen,
            ),
            const SizedBox(height: 12),
            Text(
              'Successfully Imported $_importedSuccessCount Herbs!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$_importedOtherUsesCount traditional use records linked${_importedErrorCount > 0 ? ' • $_importedErrorCount failed' : ''}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _handleBack,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Return to Herbs'),
                  style: FilledButton.styleFrom(backgroundColor: _primaryGreen),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStep = 2;
                      _selectedFileName = null;
                      _parsedRows = [];
                      _importCompleted = false;
                    });
                  },
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Import Another File'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepBanner(
          stepBadge: 'STEP 4 OF 4',
          title: 'Review & Execute Import',
          subtitle:
              'File: ${_selectedFileName ?? "None"} • $validCount valid row(s) ready to import.',
          icon: Icons.fact_check_outlined,
        ),
        const SizedBox(height: 14),

        // Filter & Progress bar container
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('All ($totalCount)'),
                      selected: _reviewFilter == _ReviewFilter.all,
                      onSelected: (_) =>
                          setState(() => _reviewFilter = _ReviewFilter.all),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Ready ($validCount)'),
                      selected: _reviewFilter == _ReviewFilter.valid,
                      onSelected: (_) =>
                          setState(() => _reviewFilter = _ReviewFilter.valid),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Rule Warnings/Errors ($issueCount)'),
                      selected: _reviewFilter == _ReviewFilter.issues,
                      onSelected: (_) =>
                          setState(() => _reviewFilter = _ReviewFilter.issues),
                    ),
                  ],
                ),
              ),
              if (_isImporting) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _importProgress,
                  color: _primaryGreen,
                  backgroundColor: const Color(0xFFE2E8F0),
                ),
                const SizedBox(height: 6),
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _primaryGreen,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (filteredRows.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: const Text('No rows match the selected filter.'),
          )
        else if (isMobile)
          // Mobile: ListTiles
          Material(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredRows.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final row = filteredRows[index];
                final h = row.herb;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: row.isValid
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFEF2F2),
                    child: Icon(
                      row.isValid
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: row.isValid
                          ? _primaryGreen
                          : const Color(0xFFDC2626),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    h.nameEn.isEmpty
                        ? 'Row #${row.rowNumber}: Missing Common Name'
                        : h.nameEn,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: row.isValid
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (h.scientificName != null &&
                          h.scientificName!.isNotEmpty)
                        Text(
                          h.scientificName!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      if (!row.isValid)
                        Text(
                          row.errors.join(', '),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFDC2626),
                          ),
                        )
                      else if (row.warnings.isNotEmpty)
                        Text(
                          row.warnings.join(', '),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFB45309),
                          ),
                        ),
                    ],
                  ),
                  trailing: Text(
                    '#${row.rowNumber}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                );
              },
            ),
          )
        else
          // Desktop: Grid Cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisExtent: 148,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filteredRows.length,
            itemBuilder: (context, index) {
              final row = filteredRows[index];
              final h = row.herb;
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: row.isValid
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFFFECACA),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            row.isValid
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            size: 18,
                            color: row.isValid
                                ? _primaryGreen
                                : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              h.nameEn.isEmpty
                                  ? 'Missing Common Name'
                                  : h.nameEn,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: row.isValid
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                          Text(
                            'Row #${row.rowNumber}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        h.scientificName ?? 'No scientific name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          if (h.family != null && h.family!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                h.family!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          const Spacer(),
                          if (row.otherUses.isNotEmpty)
                            Text(
                              '${row.otherUses.length} traditional uses',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _primaryGreen,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ===========================================================================
  // BOTTOM STEP CONTROLS
  // ===========================================================================

  Widget _buildBottomStepControls(ResponsiveSize rs, bool isMobile) {
    if (_importCompleted) return const SizedBox.shrink();

    final validCount = _parsedRows.where((r) => r.isValid).length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: rs.defaultPadding,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                OutlinedButton.icon(
                  onPressed: _isImporting
                      ? null
                      : () => setState(() => _currentStep -= 1),
                  icon: const Icon(Icons.arrow_back_rounded, size: 17),
                  label: Text(isMobile ? 'Back' : 'Previous Step'),
                )
              else
                TextButton(
                  onPressed: _isImporting ? null : _handleBack,
                  child: const Text('Cancel'),
                ),
              if (_currentStep == 0)
                FilledButton.icon(
                  onPressed: () => setState(() => _currentStep = 1),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                  label: Text(isMobile ? 'Next: Template' : 'Next: Download Template'),
                  style: FilledButton.styleFrom(backgroundColor: _primaryGreen),
                )
              else if (_currentStep == 1)
                FilledButton.icon(
                  onPressed: () => setState(() => _currentStep = 2),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                  label: Text(isMobile ? 'Next: Upload' : 'Next: Upload File'),
                  style: FilledButton.styleFrom(backgroundColor: _primaryGreen),
                )
              else if (_currentStep == 2)
                FilledButton.icon(
                  onPressed: _parsedRows.isEmpty
                      ? _pickAndParseFile
                      : () => setState(() => _currentStep = 3),
                  icon: Icon(
                    _parsedRows.isEmpty
                        ? Icons.upload_file_rounded
                        : Icons.arrow_forward_rounded,
                    size: 17,
                  ),
                  label: Text(
                    _parsedRows.isEmpty
                        ? 'Select File'
                        : 'Next: Review ($validCount)',
                  ),
                  style: FilledButton.styleFrom(backgroundColor: _primaryGreen),
                )
              else if (_currentStep == 3)
                FilledButton.icon(
                  onPressed:
                      (_isImporting || validCount == 0) ? null : _executeImport,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_done_rounded, size: 17),
                  label: Text(
                    _isImporting
                        ? 'Importing...'
                        : 'Import $validCount Herbs',
                  ),
                  style: FilledButton.styleFrom(backgroundColor: _primaryGreen),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportRuleSpec {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final bool isRequired;

  const _ImportRuleSpec({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.isRequired,
  });
}

class _ColumnRuleSpec {
  final String keyName;
  final String label;
  final bool required;
  final String example;

  const _ColumnRuleSpec({
    required this.keyName,
    required this.label,
    required this.required,
    required this.example,
  });
}

class _RuleBadge extends StatelessWidget {
  final bool isRequired;

  const _RuleBadge({required this.isRequired});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isRequired ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isRequired ? 'Required' : 'Optional',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: isRequired
              ? const Color(0xFFDC2626)
              : const Color(0xFF475569),
        ),
      ),
    );
  }
}

class _StepBanner extends StatelessWidget {
  final String stepBadge;
  final String title;
  final String subtitle;
  final IconData icon;

  const _StepBanner({
    required this.stepBadge,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stepBadge,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
