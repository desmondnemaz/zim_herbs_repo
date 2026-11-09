import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zim_herbs_repo/features/admin/herb_management/data/services/herb_spreadsheet_service.dart';

void main() {
  group('HerbSpreadsheetService Tests', () {
    test('generateStandardExcelTemplate creates non-empty bytes', () {
      final bytes = HerbSpreadsheetService.generateStandardExcelTemplate();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('generateStandardCsvTemplate creates valid CSV string with standard headers', () {
      final csvString = HerbSpreadsheetService.generateStandardCsvTemplate();
      expect(csvString, contains('English / common name'));
      expect(csvString, contains('Scientific name'));
      expect(csvString, contains('Shona name'));
      expect(csvString, contains('Ndebele name'));
      expect(csvString, contains('Caution'));
      expect(csvString, contains('Source'));
      expect(csvString, contains('Other uses & notes'));
      expect(csvString, contains('Lippia javanica'));
    });

    test('parseSpreadsheet correctly parses CSV with botanical and other uses', () {
      final csvString = HerbSpreadsheetService.generateStandardCsvTemplate();
      final bytes = Uint8List.fromList(utf8.encode(csvString));

      final rows = HerbSpreadsheetService.parseSpreadsheet(
        bytes: bytes,
        fileName: 'test_herbs.csv',
        currentUserId: 'test-admin-123',
      );

      expect(rows, isNotEmpty);
      final first = rows.first;
      expect(first.isValid, isTrue);
      expect(first.herb.nameEn, 'Fever Tea (Zumbani)');
      expect(first.herb.scientificName, 'Lippia javanica');
      expect(first.herb.nameSn, 'Zumbani');
      expect(first.herb.nameNd, 'Insuzwane');
      expect(first.herb.family, 'Verbenaceae');
      expect(first.herb.growthHabit, 'Shrub');
      expect(first.herb.placesFound, contains('Zimbabwe'));
      expect(first.herb.partsUsed, contains('Leaves'));
      expect(first.herb.partsUsed, contains('Twigs'));
      expect(first.herb.createdBy, 'test-admin-123');
      expect(first.herb.source, 'Public Domain');
      expect(first.herb.otherUsesNotes, contains('herbal tea'));
      expect(first.herb.description, contains('Cough and colds'));
    });
    });

    test('parseSpreadsheet correctly parses Excel bytes', () {
      final bytes = HerbSpreadsheetService.generateStandardExcelTemplate();

      final rows = HerbSpreadsheetService.parseSpreadsheet(
        bytes: bytes,
        fileName: 'test_herbs.xlsx',
        currentUserId: 'test-user-456',
      );

      expect(rows, isNotEmpty);
      final first = rows.first;
      expect(first.isValid, isTrue);
      expect(first.herb.nameEn, 'Fever Tea (Zumbani)');
      expect(first.herb.scientificName, 'Lippia javanica');
      expect(first.herb.family, 'Verbenaceae');
      expect(first.herb.growthHabit, 'Shrub');
      expect(first.otherUses, isNotEmpty);
    });

    test('flags row error when common name is missing', () {
      const invalidCsv = 'common_name_en,scientific_name\n,Lippia javanica';
      final bytes = Uint8List.fromList(utf8.encode(invalidCsv));

      final rows = HerbSpreadsheetService.parseSpreadsheet(
        bytes: bytes,
        fileName: 'invalid.csv',
      );

      expect(rows.length, 1);
      expect(rows.first.isValid, isFalse);
      expect(rows.first.errors, contains('Missing English/Common Name'));
    });
  });
}
