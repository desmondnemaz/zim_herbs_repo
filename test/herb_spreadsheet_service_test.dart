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
      expect(csvString, contains('common_name_en'));
      expect(csvString, contains('scientific_name'));
      expect(csvString, contains('places_found'));
      expect(csvString, contains('food_nutrition'));
      expect(csvString, contains('cultural_spiritual'));
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
      expect(first.herb.family, 'Verbenaceae');
      expect(first.herb.growthHabit, 'Shrub');
      expect(first.herb.placesFound, contains('Zimbabwe'));
      expect(first.herb.partsUsed, contains('Leaves'));
      expect(first.herb.partsUsed, contains('Twigs'));
      expect(first.herb.createdBy, 'test-admin-123');

      // Check parsed non-medicinal traditional uses
      expect(first.otherUses.length, greaterThanOrEqualTo(5));
      final categories = first.otherUses.map((u) => u.category).toSet();
      expect(categories, contains('food_nutrition'));
      expect(categories, contains('construction_fencing'));
      expect(categories, contains('firewood'));
      expect(categories, contains('cultural_spiritual'));
      expect(categories, contains('ritual'));
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
