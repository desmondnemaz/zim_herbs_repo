import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart' as csv;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Shared helper to encode 2D string matrices into Excel (.xlsx) or UTF-8 CSV
/// and save/share them across Desktop, Mobile, and Web.
class ReportExportHelper {
  static const Color _primaryGreen = Color(0xFF2E7D32);

  static Future<void> exportMatrix({
    required BuildContext context,
    required List<List<String>> matrix,
    required String baseFileName,
    required String sheetName,
    required bool asExcel,
  }) async {
    final fileName = asExcel ? '$baseFileName.xlsx' : '$baseFileName.csv';
    final mimeType = asExcel
        ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        : 'text/csv';

    final bytes = asExcel
        ? encodeAsXlsx(matrix, sheetName)
        : encodeAsCsv(matrix);

    bool saved = false;

    try {
      final result = await FilePickerPlatform.instance.saveFile(
        dialogTitle: 'Save Report ($fileName)',
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
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
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Saved report to Downloads: $fileName'),
                    backgroundColor: _primaryGreen,
                  ),
                );
              }
              return;
            }
          }
        }
        throw Exception('Unable to save report: $printingError');
      }
    }

    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported $fileName successfully'),
          backgroundColor: _primaryGreen,
        ),
      );
    }
  }

  static Uint8List encodeAsCsv(List<List<String>> matrix) {
    final csvContent = csv.csv.encode(matrix);
    final utf8Bytes = utf8.encode(csvContent);
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8Bytes]);
  }

  static Uint8List encodeAsXlsx(List<List<String>> allRows, String sheetName) {
    final sharedStrings = <String>[];
    final stringIndexMap = <String, int>{};

    int getSharedStringIndex(String str) {
      if (stringIndexMap.containsKey(str)) return stringIndexMap[str]!;
      final idx = sharedStrings.length;
      sharedStrings.add(str);
      stringIndexMap[str] = idx;
      return idx;
    }

    String colIndexToLetter(int index) {
      String result = '';
      int col = index;
      while (col >= 0) {
        result = String.fromCharCode((col % 26) + 65) + result;
        col = (col ~/ 26) - 1;
      }
      return result;
    }

    String escapeXml(String text) {
      return text
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&apos;');
    }

    final sheetXmlBuf = StringBuffer();
    sheetXmlBuf.writeln(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
    );
    sheetXmlBuf.writeln(
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
    );
    sheetXmlBuf.writeln('  <sheetData>');

    for (int r = 0; r < allRows.length; r++) {
      final row = allRows[r];
      final rowNum = r + 1;
      sheetXmlBuf.writeln('    <row r="$rowNum">');
      for (int c = 0; c < row.length; c++) {
        final colLetter = colIndexToLetter(c);
        final cellRef = '$colLetter$rowNum';
        final val = row[c];
        final strIndex = getSharedStringIndex(val);
        sheetXmlBuf.writeln(
          '      <c r="$cellRef" t="s"><v>$strIndex</v></c>',
        );
      }
      sheetXmlBuf.writeln('    </row>');
    }

    sheetXmlBuf.writeln('  </sheetData>');
    sheetXmlBuf.writeln('</worksheet>');

    final sharedStringsXmlBuf = StringBuffer();
    sharedStringsXmlBuf.writeln(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
    );
    sharedStringsXmlBuf.writeln(
      '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${sharedStrings.length}" uniqueCount="${sharedStrings.length}">',
    );
    for (final s in sharedStrings) {
      sharedStringsXmlBuf.writeln('  <si><t>${escapeXml(s)}</t></si>');
    }
    sharedStringsXmlBuf.writeln('</sst>');

    const contentTypesXml =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
        '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
        '  <Default Extension="xml" ContentType="application/xml"/>\n'
        '  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>\n'
        '  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>\n'
        '  <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>\n'
        '</Types>';

    const packageRelsXml =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>\n'
        '</Relationships>';

    final workbookXml =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">\n'
        '  <sheets>\n'
        '    <sheet name="${escapeXml(sheetName)}" sheetId="1" r:id="rId1"/>\n'
        '  </sheets>\n'
        '</workbook>';

    const workbookRelsXml =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>\n'
        '  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>\n'
        '</Relationships>';

    final archive = Archive();
    void addXml(String path, String xmlStr) {
      final bytes = utf8.encode(xmlStr);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    addXml('[Content_Types].xml', contentTypesXml);
    addXml('_rels/.rels', packageRelsXml);
    addXml('xl/workbook.xml', workbookXml);
    addXml('xl/_rels/workbook.xml.rels', workbookRelsXml);
    addXml('xl/sharedStrings.xml', sharedStringsXmlBuf.toString());
    addXml('xl/worksheets/sheet1.xml', sheetXmlBuf.toString());

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }
}

/// Compact, consistent download buttons (⬇ Excel and ⬇ CSV) used across report headers.
class ReportExportButtons extends StatelessWidget {
  final VoidCallback? onExportExcel;
  final VoidCallback? onExportCsv;

  const ReportExportButtons({
    super.key,
    required this.onExportExcel,
    required this.onExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: onExportExcel,
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Excel'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onExportCsv,
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('CSV'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2E7D32),
            side: const BorderSide(color: Color(0xFF2E7D32)),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}

/// Column definition for [StickyReportDataTable].
class StickyDataColumn {
  final String label;
  final int flex;
  final bool numeric;

  const StickyDataColumn({
    required this.label,
    this.flex = 2,
    this.numeric = false,
  });
}

/// Row definition for [StickyReportDataTable].
class StickyDataRow {
  final List<Widget> cells;
  final Color? color;

  const StickyDataRow({
    required this.cells,
    this.color,
  });
}

/// Sticky-header full-width paginated table modeled directly on the
/// User Management table (`_buildDataTable` in `user_management_screen.dart`).
class StickyReportDataTable extends StatefulWidget {
  final List<StickyDataColumn> columns;
  final List<StickyDataRow> rows;
  final List<StickyDataRow> pinnedBottomRows;
  final Widget? extraFooter;
  final double minTableWidth;
  final int initialRowsPerPage;

  const StickyReportDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.pinnedBottomRows = const [],
    this.extraFooter,
    this.minTableWidth = 750,
    this.initialRowsPerPage = 10,
  });

  @override
  State<StickyReportDataTable> createState() => _StickyReportDataTableState();
}

class _StickyReportDataTableState extends State<StickyReportDataTable> {
  late int _rowsPerPage;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.initialRowsPerPage;
  }

  @override
  void didUpdateWidget(covariant StickyReportDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final total = widget.rows.length;
    final maxPage = total == 0 ? 0 : ((total - 1) ~/ _rowsPerPage);
    if (_currentPage > maxPage) {
      _currentPage = maxPage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRows = widget.rows.length;
    final startIndex = (_currentPage * _rowsPerPage).clamp(0, totalRows);
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalRows);
    final pagedRows = widget.rows.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < widget.minTableWidth;

          // Sticky Header (matching User Management table)
          final Widget header = Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
            ),
            child: Row(
              children: List.generate(widget.columns.length, (i) {
                final col = widget.columns[i];
                return Expanded(
                  flex: col.flex,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i < widget.columns.length - 1 ? 12 : 0,
                    ),
                    child: Align(
                      alignment: col.numeric
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Text(
                        col.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );

          // Scrollable Body Rows (matching User Management ListView.builder)
          final allDisplayRows = [...pagedRows, ...widget.pinnedBottomRows];

          final Widget rowsWidget = allDisplayRows.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No records found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: false,
                  physics: const BouncingScrollPhysics(),
                  itemCount: allDisplayRows.length,
                  itemBuilder: (context, index) {
                    final row = allDisplayRows[index];
                    return Container(
                      color: row.color ?? Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      child: Row(
                        children: List.generate(widget.columns.length, (colIdx) {
                          final col = widget.columns[colIdx];
                          return Expanded(
                            flex: col.flex,
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: colIdx < widget.columns.length - 1
                                    ? 12
                                    : 0,
                              ),
                              child: Align(
                                alignment: col.numeric
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: row.cells[colIdx],
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                );

          // Pagination Footer (matching User Management table)
          final Widget footer = Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Rows per page: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    DropdownButton<int>(
                      value: _rowsPerPage,
                      underline: const SizedBox(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      items: const [10, 25, 50, 100]
                          .map(
                            (n) => DropdownMenuItem(
                              value: n,
                              child: Text('$n'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _rowsPerPage = val;
                            _currentPage = 0;
                          });
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      totalRows == 0
                          ? '0 of 0'
                          : '${startIndex + 1}-$endIndex of $totalRows',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      tooltip: 'Previous page',
                      onPressed: _currentPage > 0
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      tooltip: 'Next page',
                      onPressed: endIndex < totalRows
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          );

          final tableColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Expanded(child: rowsWidget),
              if (widget.extraFooter != null) widget.extraFooter!,
              footer,
            ],
          );

          if (isNarrow) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: widget.minTableWidth,
                child: tableColumn,
              ),
            );
          }

          return tableColumn;
        },
      ),
    );
  }
}

