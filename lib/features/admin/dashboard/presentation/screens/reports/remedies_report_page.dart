import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'report_export_helper.dart';

/// Dedicated full-page report for viewing and exporting Remedies & Formulations.
class RemediesReportPage extends StatefulWidget {
  final VoidCallback? onBack;

  const RemediesReportPage({super.key, this.onBack});

  @override
  State<RemediesReportPage> createState() => _RemediesReportPageState();
}

class _RemediesReportPageState extends State<RemediesReportPage> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoading = true;
  bool _isExporting = false;
  List<Map<String, dynamic>> _remedies = [];

  @override
  void initState() {
    super.initState();
    _loadRemedies();
  }

  Future<void> _loadRemedies() async {
    setState(() => _isLoading = true);
    try {
      final res = await _client
          .from('remedies')
          .select()
          .order('name', ascending: true);
      if (mounted) {
        setState(() {
          _remedies = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<List<String>> _buildMatrix() {
    final headers = [
      'Remedy Name',
      'Method of Use',
      'Preparation',
      'Adult Dosage',
      'Infant Dosage',
      'Frequency',
      'Duration',
      'Status',
    ];
    final rows = _remedies.map((r) {
      final status = RecordValidationStatus.fromString(
        r['validation_status'] as String?,
      );
      return [
        (r['name'] ?? '').toString(),
        (r['method_of_use'] ?? '').toString(),
        (r['preparation'] ?? '').toString(),
        (r['dosage_adults'] ?? '').toString(),
        (r['dosage_infants'] ?? '').toString(),
        (r['frequency'] ?? '').toString(),
        (r['duration'] ?? '').toString(),
        status.label,
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
        baseFileName: 'zim_herbs_remedies_report',
        sheetName: 'Remedies Report',
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
              title: 'Remedies Report',
              onBack: widget.onBack,
            ),
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Remedies & Formulations Report',
              subtitle:
                  'Traditional preparations, dosages & approval state (${_remedies.length} remedies)',
              icon: Icons.healing_outlined,
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
                            minTableWidth: 820,
                            columns: const [
                              StickyDataColumn(label: 'Remedy Name', flex: 3),
                              StickyDataColumn(label: 'Method of Use', flex: 2),
                              StickyDataColumn(label: 'Adult Dosage', flex: 2),
                              StickyDataColumn(label: 'Infant Dosage', flex: 2),
                              StickyDataColumn(label: 'Frequency', flex: 2),
                              StickyDataColumn(label: 'Status', flex: 2),
                            ],
                            rows: _remedies.map((r) {
                              final status = RecordValidationStatus.fromString(
                                r['validation_status'] as String?,
                              );
                              return StickyDataRow(
                                cells: [
                                  Text(
                                    (r['name'] ?? '-').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    (r['method_of_use'] ?? '-').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    (r['dosage_adults'] ?? '-').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    (r['dosage_infants'] ?? '-').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    (r['frequency'] ?? '-').toString(),
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
                                      color: status.color.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: status.color,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      status.label.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: status.color,
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

