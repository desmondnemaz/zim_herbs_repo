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
      number: 'Guideline 1',
      title: 'Use Microsoft Excel (.xlsx) or CSV (.csv)',
      description:
          'Save your file as a standard Microsoft Excel workbook (.xlsx) or UTF-8 CSV (.csv). The importer automatically detects the columns in the first worksheet.',
      tip: 'Excel (.xlsx) is recommended for best character support with accents and Shona apostrophes.',
      icon: Icons.description_outlined,
      isRequired: true,
    ),
    _ImportRuleSpec(
      number: 'Guideline 2',
      title: 'Keep Column Titles in Row 1',
      description:
          'The first row of your spreadsheet must contain the column header names (such as "Shona name", "English / common name", "Scientific name"). Your plant records start on Row 2.',
      tip: 'Do not add banner titles, logos, or empty rows above Row 1.',
      icon: Icons.table_chart_outlined,
      isRequired: true,
    ),
    _ImportRuleSpec(
      number: 'Guideline 3',
      title: 'Provide at Least One Plant Name',
      description:
          'Each row needs a name so the herb can be identified. You can enter an English name, a Shona name, or a Scientific name. If there is no English name, the Shona name is automatically used as the main title.',
      tip: 'Flexible: Zimbabwean plants without an English name (e.g. Chifumuro, Rufuri) are fully supported.',
      icon: Icons.local_florist_outlined,
      isRequired: true,
    ),
    _ImportRuleSpec(
      number: 'Guideline 4',
      title: 'Fill What You Know — Blanks Are Allowed',
      description:
          'You do not need complete data for every column. Leave unknown fields blank (such as family, caution, or ailments). You or other contributors can enrich them later.',
      tip: 'Separate multiple values (e.g. Leaves, Roots, Bark) with commas or semicolons.',
      icon: Icons.playlist_add_check_rounded,
      isRequired: false,
    ),
  ];

  static const List<_ColumnCategory> _columnCategories = [
    _ColumnCategory(
      title: 'Plant & Botanical Identity',
      subtitle: 'Local names, scientific classification, and plant growth habit',
      icon: Icons.local_florist_rounded,
      color: Color(0xFF2E7D32),
      columns: [
        _ColumnRuleSpec(
          keyName: 'Shona name',
          label: 'Shona Name',
          required: false,
          description:
              'Traditional Shona plant name. Used as main title if English name is not provided.',
          example: 'Mugan\'acha, Mupfura, Zumbani',
        ),
        _ColumnRuleSpec(
          keyName: 'Ndebele name',
          label: 'Ndebele Name',
          required: false,
          description:
              'Traditional Ndebele plant name, or "Not found" if unrecorded.',
          example: 'umganu, Insuzwane, umkhuna',
        ),
        _ColumnRuleSpec(
          keyName: 'English / common name',
          label: 'Common English Name',
          required: true,
          description:
              'Standard English or common name. If not known, enter the Shona name.',
          example: 'Live-long, Marula, Fever tea, Wild grape',
        ),
        _ColumnRuleSpec(
          keyName: 'Scientific name',
          label: 'Scientific / Botanical Name',
          required: false,
          description:
              'Binomial Latin botanical classification (Genus and species).',
          example: 'Lannea discolor, Sclerocarya birrea',
        ),
        _ColumnRuleSpec(
          keyName: 'Family',
          label: 'Botanical Family',
          required: false,
          description: 'Plant taxonomic family.',
          example: 'Anacardiaceae, Verbenaceae, Fabaceae',
        ),
        _ColumnRuleSpec(
          keyName: 'Growth habit',
          label: 'Growth Habit',
          required: false,
          description:
              'Biological plant form: Tree, Shrub, Herb, Climber, or Succulent.',
          example: 'Tree, Shrub, Herb, Climber',
        ),
      ],
    ),
    _ColumnCategory(
      title: 'Traditional Uses & Health',
      subtitle:
          'Harvested plant parts, treated ailments, and practical community uses',
      icon: Icons.healing_rounded,
      color: Color(0xFFB45309),
      columns: [
        _ColumnRuleSpec(
          keyName: 'Part used',
          label: 'Plant Part Used',
          required: false,
          description:
              'Harvested parts (separate multiples with commas, semicolons, or slashes).',
          example: 'Leaves, Roots, Bark, Fibre, Seeds',
        ),
        _ColumnRuleSpec(
          keyName: 'Traditional use (ailments treated)',
          label: 'Traditional Medicinal Uses',
          required: false,
          description:
              'Ailments treated and method of preparation / consumption.',
          example: 'Heavy menstrual flow; sore eyes (extract); fevers & cough',
        ),
        _ColumnRuleSpec(
          keyName: 'Ailment categories',
          label: 'Ailment Categories',
          required: false,
          description: 'High-level medical categories for search and filtering.',
          example: 'Women\'s health; Eyes & ears; Digestive; Respiratory',
        ),
        _ColumnRuleSpec(
          keyName: 'Other uses & notes',
          label: 'Other Uses & Notes',
          required: false,
          description:
              'Practical, nutritional, cultural, or domestic non-medicinal uses.',
          example: 'Edible grape-like fruit; poles used for fencing; firewood',
        ),
      ],
    ),
    _ColumnCategory(
      title: 'Location, Safety & Citations',
      subtitle: 'Where found in Zimbabwe, origin, precautions, and references',
      icon: Icons.shield_outlined,
      color: Color(0xFF1D4ED8),
      columns: [
        _ColumnRuleSpec(
          keyName: 'Where commonly found / used',
          label: 'Where Found / Distribution',
          required: false,
          description:
              'Districts or provinces in Zimbabwe where commonly found or practiced.',
          example: 'South-central Zimbabwe (Masvingo & Midlands), Buhera',
        ),
        _ColumnRuleSpec(
          keyName: 'Exotic to Zimbabwe',
          label: 'Exotic to Zimbabwe',
          required: false,
          description:
              '"No" for native/indigenous Zimbabwean plants; "Yes" for introduced/exotic species.',
          example: 'No (Indigenous) or Yes (Exotic)',
        ),
        _ColumnRuleSpec(
          keyName: 'Caution',
          label: 'Caution / Warnings',
          required: false,
          description:
              'Toxicity, contraindications, pregnancy warnings, or "No specific warning recorded".',
          example: 'Avoid high doses in pregnancy; Contains potent alkaloids',
        ),
        _ColumnRuleSpec(
          keyName: 'Source',
          label: 'Source / References',
          required: false,
          description:
              'Ethnobotanical literature, research paper, community elder, or public domain.',
          example: 'Public Domain, Maroyi 2013, ZimbOriginal',
        ),
      ],
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

    final client = Supabase.instance.client;
    final dataSource = HerbRemoteDataSource(client);
    final HerbRepository repo = HerbRepositoryImpl(dataSource);

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
        const _StepBanner(
          stepBadge: 'STEP 1 OF 4',
          title: 'Spreadsheet Import Guidelines',
          subtitle:
              'Follow these 4 simple guidelines to ensure your Zimbabwean botanical records import smoothly and cleanly.',
          icon: Icons.menu_book_rounded,
        ),
        const SizedBox(height: 16),

        // Quick 3-Step Process Overview
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.timeline_rounded,
                    color: _primaryGreen,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'How Import Works in 3 Quick Steps',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              isMobile
                  ? Column(
                      children: [
                        _buildWorkflowMiniStep(
                          stepNum: '1',
                          title: 'Download Template',
                          description:
                              'Get the pre-formatted Excel file in Step 2 with sample Zimbabwean plants.',
                          isLast: false,
                        ),
                        const SizedBox(height: 12),
                        _buildWorkflowMiniStep(
                          stepNum: '2',
                          title: 'Add Your Plants',
                          description:
                              'Paste or type your herb data. Row 1 has headers; empty cells are OK.',
                          isLast: false,
                        ),
                        const SizedBox(height: 12),
                        _buildWorkflowMiniStep(
                          stepNum: '3',
                          title: 'Upload & Review',
                          description:
                              'Upload in Step 3, preview each plant in Step 4, and import with one click.',
                          isLast: true,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildWorkflowMiniStep(
                            stepNum: '1',
                            title: 'Download Template',
                            description:
                                'Get the pre-formatted Excel file in Step 2 with sample Zimbabwean plants.',
                            isLast: false,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: _buildWorkflowMiniStep(
                            stepNum: '2',
                            title: 'Add Your Plants',
                            description:
                                'Paste or type your herb data. Row 1 has headers; empty cells are OK.',
                            isLast: false,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: _buildWorkflowMiniStep(
                            stepNum: '3',
                            title: 'Upload & Review',
                            description:
                                'Upload in Step 3, preview each plant in Step 4, and import with one click.',
                            isLast: true,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'The 4 Key Import Guidelines',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Guideline Cards
        ..._importRules.map((rule) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: rule.isRequired
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: rule.isRequired
                              ? const Color(0xFFEAF5EB)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          rule.icon,
                          size: 20,
                          color: rule.isRequired
                              ? _primaryGreen
                              : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        rule.number,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      _RuleBadge(
                        isRequired: rule.isRequired,
                        label: rule.isRequired ? 'Required' : 'Flexible',
                        color: rule.isRequired
                            ? _primaryGreen
                            : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rule.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rule.description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rule.tip,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5EB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: _primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ready to start? Download our ready-to-fill spreadsheet template in the next step, or proceed to Step 3 if your file is already prepared.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1B5E20),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => setState(() => _currentStep = 1),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('View Template'),
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowMiniStep({
    required String stepNum,
    required String title,
    required String description,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _primaryGreen,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNum,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ),
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
        const _StepBanner(
          stepBadge: 'STEP 2 OF 4',
          title: 'Download Template & Column Guide',
          subtitle:
              'Download the pre-formatted Excel or CSV template, or review how to organize the 14 supported columns.',
          icon: Icons.file_download_outlined,
        ),
        const SizedBox(height: 16),

        // Download Action Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.table_view_rounded,
                      color: _primaryGreen,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Official 14-Column Herbal Template',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Includes all 14 standard columns with sample Zimbabwean plants (Live-long, Wild grape, Mango, Marula) already filled in.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _downloadTemplate(asExcel: true),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        isMobile
                            ? 'Download Excel (.xlsx)'
                            : 'Download Excel Spreadsheet (.xlsx)',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadTemplate(asExcel: false),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        isMobile ? 'Download CSV' : 'Download CSV File (.csv)',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryGreen,
                        side: const BorderSide(color: _primaryGreen, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The 14 Supported Columns Explained',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Grouped into 3 logical categories. Only one plant name is required — all other columns are optional.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Grouped Column Categories
        ..._columnCategories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.08),
                      border: Border(
                        bottom: BorderSide(
                          color: category.color.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: category.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            category.icon,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.title,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: category.color,
                                ),
                              ),
                              Text(
                                category.subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: category.color.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            '${category.columns.length} Columns',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: category.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Column list inside category
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: category.columns.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (context, colIndex) {
                      final col = category.columns[colIndex];
                      return Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Text(
                                    col.keyName,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    col.label,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                _RuleBadge(
                                  isRequired: col.required,
                                  label: col.required
                                      ? 'Key Identifier'
                                      : 'Optional',
                                  color: col.required
                                      ? _primaryGreen
                                      : const Color(0xFF64748B),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              col.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Example: ${col.example}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5EB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                color: _primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Have your spreadsheet ready? Proceed to Step 3 to select and upload your file.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1B5E20),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => setState(() => _currentStep = 2),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Proceed to Upload'),
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
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
  final String tip;
  final IconData icon;
  final bool isRequired;

  const _ImportRuleSpec({
    required this.number,
    required this.title,
    required this.description,
    required this.tip,
    required this.icon,
    required this.isRequired,
  });
}

class _ColumnRuleSpec {
  final String keyName;
  final String label;
  final bool required;
  final String description;
  final String example;

  const _ColumnRuleSpec({
    required this.keyName,
    required this.label,
    required this.required,
    required this.description,
    required this.example,
  });
}

class _ColumnCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_ColumnRuleSpec> columns;

  const _ColumnCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.columns,
  });
}

class _RuleBadge extends StatelessWidget {
  final bool isRequired;
  final String? label;
  final Color? color;

  const _RuleBadge({
    required this.isRequired,
    this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = label ?? (isRequired ? 'Required' : 'Optional');
    final textColor = color ??
        (isRequired ? const Color(0xFFDC2626) : const Color(0xFF475569));
    final bgColor = color != null
        ? color!.withValues(alpha: 0.12)
        : (isRequired ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
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
