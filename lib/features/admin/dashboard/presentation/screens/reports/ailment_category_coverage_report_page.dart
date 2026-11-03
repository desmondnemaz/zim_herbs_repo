import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'report_export_helper.dart';

class _AilmentCategoryReportRow {
  final AilmentCategory category;
  final String categoryLabel;
  final int plantCount;
  final double sharePercent;

  const _AilmentCategoryReportRow({
    required this.category,
    required this.categoryLabel,
    required this.plantCount,
    required this.sharePercent,
  });

  String get formattedShare => '${sharePercent.toStringAsFixed(1)}%';
}

/// Dedicated full-page report showing the Ailment Category Plant Coverage Table
/// (using our 17 AilmentCategory classifications) with Excel (.xlsx) and CSV export.
class AilmentCategoryCoverageReportPage extends StatefulWidget {
  final VoidCallback? onBack;

  const AilmentCategoryCoverageReportPage({super.key, this.onBack});

  @override
  State<AilmentCategoryCoverageReportPage> createState() =>
      _AilmentCategoryCoverageReportPageState();
}

class _AilmentCategoryCoverageReportPageState
    extends State<AilmentCategoryCoverageReportPage> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoading = true;
  bool _isExporting = false;
  List<_AilmentCategoryReportRow> _rows = [];
  int _totalPlantsCount = 0;
  int _exoticSpeciesCount = 0;
  int _detailedPlantsCount = 0;

  static const List<AilmentCategory> _reportCategoryOrder = [
    AilmentCategory.digestive,
    AilmentCategory.respiratory,
    AilmentCategory.sexualHealth,
    AilmentCategory.reproductiveHealth,
    AilmentCategory.painJoints,
    AilmentCategory.skinWounds,
    AilmentCategory.eyesEars,
    AilmentCategory.dental,
    AilmentCategory.parasites,
    AilmentCategory.fever,
    AilmentCategory.childHealth,
    AilmentCategory.nervousSystem,
    AilmentCategory.heartBlood,
    AilmentCategory.immunityHormones,
    AilmentCategory.infections,
    AilmentCategory.snakebite,
    AilmentCategory.otherUses,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> ailmentsData = [];
      try {
        final res = await _client.from('ailments').select();
        ailmentsData = List<Map<String, dynamic>>.from(res);
      } catch (_) {
        try {
          final res = await _client.from('conditions').select();
          ailmentsData = List<Map<String, dynamic>>.from(res);
        } catch (_) {}
      }

      final results = await Future.wait([
        _client
            .from('herbs')
            .select()
            .then((v) => List<Map<String, dynamic>>.from(v))
            .catchError((_) => <Map<String, dynamic>>[]),
        _client
            .from('remedies')
            .select('*, remedy_herbs(herb_id)')
            .then((v) => List<Map<String, dynamic>>.from(v))
            .catchError((_) async {
              final fallback = await _client.from('remedies').select();
              return List<Map<String, dynamic>>.from(fallback);
            })
            .catchError((_) => <Map<String, dynamic>>[]),
        _client
            .from('herb_other_uses')
            .select('herb_id')
            .then((v) => List<Map<String, dynamic>>.from(v))
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);

      final herbsData = results[0];
      final remediesData = results[1];
      final otherUsesData = results[2];

      final ailmentCategoryById = <String, AilmentCategory>{};

      for (final a in ailmentsData) {
        final id = (a['id'] ?? '').toString();
        final rawCat =
            (a['ailment_category'] ?? a['body_system'] ?? 'other_uses')
                .toString();
        final cat = ailmentCategoryFromString(rawCat);
        if (id.isNotEmpty) ailmentCategoryById[id] = cat;
      }

      final plantIdsByCategory = <AilmentCategory, Set<String>>{
        for (final c in AilmentCategory.values) c: <String>{},
      };

      for (final r in remediesData) {
        final conditionId =
            (r['condition_id'] ?? r['ailment_id'] ?? '').toString();
        final category = ailmentCategoryById[conditionId];
        if (category == null) continue;

        final rawRemedyHerbs = r['remedy_herbs'] ?? r['treatment_herbs'];
        if (rawRemedyHerbs is List) {
          for (final rh in rawRemedyHerbs) {
            if (rh is Map) {
              final herbId = (rh['herb_id'] ?? '').toString();
              if (herbId.isNotEmpty) {
                plantIdsByCategory[category]!.add(herbId);
              }
            }
          }
        }
      }

      for (final u in otherUsesData) {
        final herbId = (u['herb_id'] ?? '').toString();
        if (herbId.isNotEmpty) {
          plantIdsByCategory[AilmentCategory.otherUses]!.add(herbId);
        }
      }

      final totalPlants = herbsData.length;
      int exoticCount = 0;
      int detailedCount = 0;

      for (final h in herbsData) {
        final exotic = (h['exotic_status'] ?? 'Indigenous')
            .toString()
            .trim()
            .toLowerCase();
        if (exotic.isNotEmpty && !exotic.contains('indigenous')) {
          exoticCount++;
        }
        final desc = (h['description'] ?? '').toString().trim();
        final sci = (h['scientific_name'] ?? '').toString().trim();
        if (desc.isNotEmpty && sci.isNotEmpty) {
          detailedCount++;
        }
      }

      final builtRows = _reportCategoryOrder.map((cat) {
        final count = plantIdsByCategory[cat]?.length ?? 0;
        final share = totalPlants > 0 ? (count / totalPlants) * 100.0 : 0.0;

        return _AilmentCategoryReportRow(
          category: cat,
          categoryLabel: ailmentCategoryLabel(cat),
          plantCount: count,
          sharePercent: share,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _rows = builtRows;
          _totalPlantsCount = totalPlants;
          _exoticSpeciesCount = exoticCount;
          _detailedPlantsCount = detailedCount;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<List<String>> _buildMatrix() {
    return [
      ['Ailment category', 'No. of plants', 'Share of plants'],
      ..._rows.map(
        (r) => [
          r.categoryLabel,
          '${r.plantCount}',
          r.formattedShare,
        ],
      ),
      ['', '', ''],
      ['Total plants in dataset', '$_totalPlantsCount', ''],
      ['Exotic species', '$_exoticSpeciesCount', ''],
      ['Plants with detailed profiles', '$_detailedPlantsCount', ''],
      ['', '', ''],
      [
        'Note: a plant used for several ailments counts in each of its categories, so the shares add up to more than 100%.',
        '',
        '',
      ],
    ];
  }

  Future<void> _export({required bool asExcel}) async {
    setState(() => _isExporting = true);
    try {
      await ReportExportHelper.exportMatrix(
        context: context,
        matrix: _buildMatrix(),
        baseFileName: 'ailment_category_plant_coverage',
        sheetName: 'Ailment Categories',
        asExcel: asExcel,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
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
              title: 'Ailment Category Report',
              onBack: widget.onBack,
            ),
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Ailment Category Plant Coverage',
              subtitle:
                  'Distribution & share of medicinal plants across the 17 AilmentCategory classifications',
              icon: Icons.table_chart_rounded,
              onBack: widget.onBack,
              trailing: ReportExportButtons(
                onExportExcel: (_isLoading || _isExporting)
                    ? null
                    : () => _export(asExcel: true),
                onExportCsv: (_isLoading || _isExporting)
                    ? null
                    : () => _export(asExcel: false),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: EdgeInsets.all(rs.defaultPadding),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 920),
                          child: _buildSpreadsheetTable(isMobile),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpreadsheetTable(bool isMobile) {
    return StickyReportDataTable(
      minTableWidth: 520,
      initialRowsPerPage: 25,
      columns: [
        const StickyDataColumn(label: 'Ailment category', flex: 5),
        StickyDataColumn(
          label: isMobile ? 'Plants' : 'No. of plants',
          flex: 2,
          numeric: true,
        ),
        StickyDataColumn(
          label: isMobile ? 'Share' : 'Share of plants',
          flex: 2,
          numeric: true,
        ),
      ],
      rows: _rows.map((row) {
        return StickyDataRow(
          cells: [
            Text(
              row.categoryLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              '${row.plantCount}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              row.formattedShare,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        );
      }).toList(),
      pinnedBottomRows: [
        _buildSummaryRow(
          label: 'Total plants in dataset',
          value: '$_totalPlantsCount',
          isBold: true,
        ),
        _buildSummaryRow(
          label: 'Exotic species',
          value: '$_exoticSpeciesCount',
          isBold: false,
        ),
        _buildSummaryRow(
          label: 'Plants with detailed profiles',
          value: '$_detailedPlantsCount',
          isBold: false,
        ),
      ],
      extraFooter: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: const Text(
          'Note: a plant used for several ailments counts in each of its categories, so the shares add up to more than 100%.',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  StickyDataRow _buildSummaryRow({
    required String label,
    required String value,
    required bool isBold,
  }) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
      fontSize: 13,
      color: const Color(0xFF1E293B),
    );

    return StickyDataRow(
      color: const Color(0xFFF8FAFC),
      cells: [
        Text(label, style: style),
        Text(value, style: style),
        const SizedBox(),
      ],
    );
  }
}

