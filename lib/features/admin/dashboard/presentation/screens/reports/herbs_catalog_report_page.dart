import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'report_export_helper.dart';

/// Dedicated full-page report for viewing and exporting the Herbs Botanical Catalog.
class HerbsCatalogReportPage extends StatefulWidget {
  final VoidCallback? onBack;

  const HerbsCatalogReportPage({super.key, this.onBack});

  @override
  State<HerbsCatalogReportPage> createState() => _HerbsCatalogReportPageState();
}

class _HerbsCatalogReportPageState extends State<HerbsCatalogReportPage> {
  static const Color _primaryGreen = Color(0xFF2E7D32);
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoading = true;
  bool _isExporting = false;
  List<Map<String, dynamic>> _herbs = [];

  @override
  void initState() {
    super.initState();
    _loadHerbs();
  }

  Future<void> _loadHerbs() async {
    setState(() => _isLoading = true);
    try {
      final res = await _client
          .from('herbs')
          .select()
          .order('name_en', ascending: true);
      if (mounted) {
        setState(() {
          _herbs = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<List<String>> _buildMatrix() {
    final headers = [
      'Common Name',
      'Scientific Name',
      'Shona Name',
      'Ndebele Name',
      'Family',
      'Growth Habit',
      'Parts Used',
      'Exotic Status',
      'Status',
    ];
    final rows = _herbs.map((h) {
      final parts = h['parts_used'];
      final partsStr =
          parts is List ? parts.join(', ') : (parts ?? '').toString();
      return [
        (h['name_en'] ?? '').toString(),
        (h['scientific_name'] ?? '').toString(),
        (h['name_sn'] ?? '').toString(),
        (h['name_nd'] ?? '').toString(),
        (h['family'] ?? '').toString(),
        (h['growth_habit'] ?? '').toString(),
        partsStr,
        (h['exotic_status'] ?? 'Indigenous').toString(),
        (h['is_approved'] == true ? 'Approved' : 'Pending'),
      ];
    }).toList();
    return [headers, ...rows];
  }

  Future<void> _export({required bool asExcel}) async {
    setState(() => _isExporting = true);
    try {
      await ReportExportHelper.exportMatrix(
        context: context,
        matrix: _buildMatrix(),
        baseFileName: 'zim_herbs_catalog_report',
        sheetName: 'Herbs Catalog',
        asExcel: asExcel,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F2),
      appBar: isDesktop
          ? null
          : AppPageAppBar(
              title: 'Herbs Catalog Report',
              onBack: widget.onBack,
            ),
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Herbs Botanical Catalog Report',
              subtitle:
                  'Complete botanical inventory (${_herbs.length} plants)',
              icon: Icons.local_florist_rounded,
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
                          constraints: const BoxConstraints(maxWidth: 1160),
                          child: StickyReportDataTable(
                            minTableWidth: 920,
                            columns: const [
                              StickyDataColumn(label: 'Common Name', flex: 3),
                              StickyDataColumn(
                                label: 'Scientific Name',
                                flex: 3,
                              ),
                              StickyDataColumn(label: 'Shona', flex: 2),
                              StickyDataColumn(label: 'Ndebele', flex: 2),
                              StickyDataColumn(label: 'Family', flex: 2),
                              StickyDataColumn(label: 'Habit', flex: 2),
                              StickyDataColumn(label: 'Origin', flex: 2),
                              StickyDataColumn(label: 'Status', flex: 2),
                            ],
                            rows: _herbs.map((h) {
                              final isApproved = h['is_approved'] == true;
                              return StickyDataRow(
                                cells: [
                                  Text(
                                    (h['name_en'] ?? '-').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    (h['scientific_name'] ?? '-').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    (h['name_sn'] ?? '-').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    (h['name_nd'] ?? '-').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    (h['family'] ?? '-').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    (h['growth_habit'] ?? '-').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    (h['exotic_status'] ?? 'Indigenous')
                                        .toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isApproved
                                              ? _primaryGreen
                                              : const Color(0xFFB45309))
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isApproved
                                            ? _primaryGreen
                                            : const Color(0xFFB45309),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      isApproved ? 'APPROVED' : 'PENDING',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isApproved
                                            ? _primaryGreen
                                            : const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

