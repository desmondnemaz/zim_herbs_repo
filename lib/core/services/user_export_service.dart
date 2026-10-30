import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart' as csv;

/// Service responsible for exporting user directory records
/// into printable PDF reports and Excel-compatible CSV files.
class UserExportService {
  /// Generates a styled, multi-page PDF document containing the user directory table
  /// and opens the native print/save dialog.
  static Future<void> exportToPdf({
    required BuildContext context,
    required List<Map<String, dynamic>> users,
    String? searchQuery,
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final formattedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final tableHeaders = ['#', 'Full Name', 'Email', 'Role(s)', 'Joined Date'];

    final tableData = <List<String>>[];
    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final fullName = (user['full_name'] as String?)?.trim();
      final email = user['email'] as String? ?? 'N/A';

      final roles = <String>[];
      if (user['is_admin'] == true) roles.add('Admin');
      if (user['is_moderator'] == true) roles.add('Moderator');
      if (user['is_supplier'] == true) roles.add('Supplier');
      if (user['is_practitioner'] == true) roles.add('Practitioner');
      if (roles.isEmpty) roles.add('Learner');

      String createdAtStr = 'N/A';
      if (user['created_at'] != null) {
        try {
          final dt = DateTime.parse(user['created_at'].toString());
          createdAtStr =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        } catch (_) {}
      }

      tableData.add([
        '${i + 1}',
        fullName?.isNotEmpty == true ? fullName! : 'Unnamed User',
        email,
        roles.join(', '),
        createdAtStr,
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Zim Herbs & HerbCircle',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.Text(
                    'User Directory Report',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated on: $formattedDate',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Total Records: ${users.length}${searchQuery != null && searchQuery.isNotEmpty ? ' (Filtered: "$searchQuery")' : ''}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.green800),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context context) => [
          pw.TableHelper.fromTextArray(
            headers: tableHeaders,
            data: tableData,
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.green800,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'zim_herbs_users_${now.millisecondsSinceEpoch}.pdf',
    );
  }

  /// Exports user records to standard Excel-compatible CSV format
  /// and opens native share/download dialog.
  static Future<void> exportToCsv({
    required BuildContext context,
    required List<Map<String, dynamic>> users,
  }) async {
    final rows = <List<dynamic>>[];

    // CSV Header row
    rows.add([
      'User ID',
      'Full Name',
      'Email',
      'Phone Number',
      'Is Admin',
      'Is Moderator',
      'Is Supplier',
      'Is Practitioner',
      'Joined Date',
    ]);

    for (final user in users) {
      rows.add([
        user['id'] ?? '',
        user['full_name'] ?? '',
        user['email'] ?? '',
        user['phone_number'] ?? '',
        user['is_admin'] == true ? 'YES' : 'NO',
        user['is_moderator'] == true ? 'YES' : 'NO',
        user['is_supplier'] == true ? 'YES' : 'NO',
        user['is_practitioner'] == true ? 'YES' : 'NO',
        user['created_at'] ?? '',
      ]);
    }

    final csvContent = csv.csv.encode(rows);
    final bytes = Uint8List.fromList(utf8.encode(csvContent));

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'zim_herbs_users_$timestamp.csv';

    await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
    );
  }
}
