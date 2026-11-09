import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart' as csv;
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/models/herb_model.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/models/herb_other_use_model.dart';

/// Represents a validated herb record parsed from a spreadsheet row.
class ParsedHerbImportRow {
  final int rowNumber;
  final HerbModel herb;
  final List<HerbOtherUseModel> otherUses;
  final List<String> warnings;
  final List<String> errors;

  bool get isValid => errors.isEmpty;

  const ParsedHerbImportRow({
    required this.rowNumber,
    required this.herb,
    this.otherUses = const [],
    this.warnings = const [],
    this.errors = const [],
  });
}

/// Service to generate standardized Excel/CSV templates and parse uploaded files.
class HerbSpreadsheetService {
  static const _uuid = Uuid();

  /// Standard column definitions
  static const List<String> standardColumns = [
    'Shona name',
    'Ndebele name',
    'English / common name',
    'Scientific name',
    'Family',
    'Growth habit',
    'Part used',
    'Traditional use (ailments treated)',
    'Ailment categories',
    'Where commonly found / used',
    'Exotic to Zimbabwe',
    'Caution',
    'Source',
    'Other uses & notes',
  ];

  static const List<String> sampleRow = [
    'Zumbani',
    'Insuzwane',
    'Fever Tea (Zumbani)',
    'Lippia javanica',
    'Verbenaceae',
    'Shrub',
    'Leaves, Twigs',
    'Cough and colds (boiled and drunk as tea). Local use: Chikosoro (cough), dzihwa (cold/flu)',
    'Respiratory; Fever',
    'South-central Zimbabwe (Masvingo & Midlands); Honde Valley',
    'No',
    'No specific warning recorded',
    'Public Domain',
    'Leaves drunk as a herbal tea; aromatic insect repellent',
  ];

  /// Generates a standardized CSV template string.
  static String generateStandardCsvTemplate() {
    return csv.csv.encode([
      standardColumns,
      sampleRow,
    ]);
  }

  /// Generates a standardized spreadsheet template string (UTF-8 CSV with BOM for seamless opening in Excel).
  static Uint8List generateStandardTemplateBytes() {
    final csvString = generateStandardCsvTemplate();
    final utf8Bytes = utf8.encode(csvString);
    final withBom = <int>[0xEF, 0xBB, 0xBF, ...utf8Bytes];
    return Uint8List.fromList(withBom);
  }

  /// Generates a valid standard .xlsx template file with headers and a sample row.
  static Uint8List generateStandardExcelTemplate() {
    final allRows = [standardColumns, sampleRow];
    final sharedStrings = <String>[];
    final stringIndexMap = <String, int>{};

    int getSharedStringIndex(String str) {
      if (stringIndexMap.containsKey(str)) {
        return stringIndexMap[str]!;
      }
      final idx = sharedStrings.length;
      sharedStrings.add(str);
      stringIndexMap[str] = idx;
      return idx;
    }

    final sheetXmlBuf = StringBuffer();
    sheetXmlBuf.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    sheetXmlBuf.writeln('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
    sheetXmlBuf.writeln('  <sheetData>');

    for (int r = 0; r < allRows.length; r++) {
      final row = allRows[r];
      final rowNum = r + 1;
      sheetXmlBuf.writeln('    <row r="$rowNum">');
      for (int c = 0; c < row.length; c++) {
        final colLetter = _colIndexToLetter(c);
        final cellRef = '$colLetter$rowNum';
        final val = row[c];
        final strIndex = getSharedStringIndex(val);
        sheetXmlBuf.writeln('      <c r="$cellRef" t="s"><v>$strIndex</v></c>');
      }
      sheetXmlBuf.writeln('    </row>');
    }

    sheetXmlBuf.writeln('  </sheetData>');
    sheetXmlBuf.writeln('</worksheet>');

    final sharedStringsXmlBuf = StringBuffer();
    sharedStringsXmlBuf.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    sharedStringsXmlBuf.writeln('<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${sharedStrings.length}" uniqueCount="${sharedStrings.length}">');
    for (final s in sharedStrings) {
      sharedStringsXmlBuf.writeln('  <si><t>${_escapeXml(s)}</t></si>');
    }
    sharedStringsXmlBuf.writeln('</sst>');

    const contentTypesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
        '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
        '  <Default Extension="xml" ContentType="application/xml"/>\n'
        '  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>\n'
        '  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>\n'
        '  <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>\n'
        '</Types>';

    const packageRelsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>\n'
        '</Relationships>';

    const workbookXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">\n'
        '  <sheets>\n'
        '    <sheet name="Zim Herbs" sheetId="1" r:id="rId1"/>\n'
        '  </sheets>\n'
        '</workbook>';

    const workbookRelsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
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

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  static String _colIndexToLetter(int index) {
    String result = '';
    int col = index;
    while (col >= 0) {
      result = String.fromCharCode((col % 26) + 65) + result;
      col = (col ~/ 26) - 1;
    }
    return result;
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Parses spreadsheet bytes (either .xlsx or .csv) into validated import rows.
  static List<ParsedHerbImportRow> parseSpreadsheet({
    required Uint8List bytes,
    required String fileName,
    String? currentUserId,
  }) {
    if (fileName.toLowerCase().endsWith('.csv') ||
        fileName.toLowerCase().endsWith('.txt')) {
      return _parseCsv(bytes, currentUserId);
    } else {
      return _parseExcel(bytes, currentUserId);
    }
  }

  static List<ParsedHerbImportRow> _parseExcel(
    Uint8List bytes,
    String? currentUserId,
  ) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      // 1. Parse sharedStrings.xml (if present)
      final sharedStrings = <String>[];
      final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
      if (sharedStringsFile != null) {
        final content = utf8.decode(sharedStringsFile.content as List<int>);
        final xml = XmlDocument.parse(content);
        for (final si in xml.findAllElements('si')) {
          final tElements = si.findAllElements('t');
          sharedStrings.add(tElements.map((e) => e.innerText).join());
        }
      }

      // 2. Locate worksheet XML
      ArchiveFile? sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
      if (sheetFile == null) {
        for (final f in archive.files) {
          if (f.name.startsWith('xl/worksheets/sheet') && f.name.endsWith('.xml')) {
            sheetFile = f;
            break;
          }
        }
      }

      if (sheetFile == null) {
        throw Exception('No worksheet found in Excel workbook');
      }

      final sheetXml =
          XmlDocument.parse(utf8.decode(sheetFile.content as List<int>));
      final rows = <List<String>>[];

      for (final rowElem in sheetXml.findAllElements('row')) {
        final rowValues = <String>[];
        for (final c in rowElem.findAllElements('c')) {
          final type = c.getAttribute('t');
          final v = c.findElements('v').firstOrNull?.innerText;
          if (v == null) {
            final isElem = c.findElements('is').firstOrNull;
            rowValues.add(
                isElem?.findElements('t').firstOrNull?.innerText.trim() ?? '');
            continue;
          }

          if (type == 's') {
            final idx = int.tryParse(v);
            if (idx != null && idx >= 0 && idx < sharedStrings.length) {
              rowValues.add(sharedStrings[idx].trim());
            } else {
              rowValues.add(v.trim());
            }
          } else {
            rowValues.add(v.trim());
          }
        }
        if (rowValues.any((cell) => cell.isNotEmpty)) {
          rows.add(rowValues);
        }
      }

      if (rows.isEmpty) return [];

      final headers = rows.first.map((e) => _normalizeHeader(e)).toList();
      final results = <ParsedHerbImportRow>[];

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.every((cell) => cell.trim().isEmpty)) continue;

        final rowMap = <String, String>{};
        for (int c = 0; c < headers.length && c < row.length; c++) {
          final header = headers[c];
          final val = row[c].trim();
          if (header.isNotEmpty && val.isNotEmpty) {
            rowMap[header] = val;
          }
        }

        results.add(_buildImportRow(rowMap, i + 1, currentUserId));
      }

      return results;
    } catch (e) {
      throw Exception('Failed to decode Excel (.xlsx) file: $e');
    }
  }

  static List<ParsedHerbImportRow> _parseCsv(
    Uint8List bytes,
    String? currentUserId,
  ) {
    // Strip UTF-8 BOM if present
    String csvString;
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      csvString = utf8.decode(bytes.sublist(3));
    } else {
      csvString = utf8.decode(bytes);
    }

    final rawRows = csv.csv.decode(csvString);
    final results = <ParsedHerbImportRow>[];
    if (rawRows.isEmpty) return results;

    final headers =
        rawRows.first.map((e) => _normalizeHeader(e.toString())).toList();

    for (int i = 1; i < rawRows.length; i++) {
      final row = rawRows[i];
      if (row.every((cell) => cell.toString().trim().isEmpty)) continue;

      final rowMap = <String, String>{};
      for (int c = 0; c < headers.length && c < row.length; c++) {
        final header = headers[c];
        final val = row[c].toString().trim();
        if (header.isNotEmpty && val.isNotEmpty) {
          rowMap[header] = val;
        }
      }

      results.add(_buildImportRow(rowMap, i + 1, currentUserId));
    }

    return results;
  }

  static String _normalizeHeader(String raw) {
    final cleaned = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-/]+'), '_')
        .replaceAll(RegExp(r'[^\w_]'), '');

    // Normalize English / Common Name aliases
    if (cleaned == 'english_name' ||
        cleaned == 'name' ||
        cleaned == 'common_name' ||
        cleaned == 'english_common_name' ||
        cleaned == 'common_name_en' ||
        cleaned == 'name_en') {
      return 'common_name_en';
    }

    // Distribution / Where found aliases
    if (cleaned == 'distribution' ||
        cleaned == 'where_found' ||
        cleaned == 'location' ||
        cleaned == 'places_found' ||
        cleaned == 'where_commonly_found' ||
        cleaned == 'where_commonly_found_used') {
      return 'places_found';
    }

    // Shona name aliases
    if (cleaned == 'shona' ||
        cleaned == 'shona_name' ||
        cleaned == 'name_shona' ||
        cleaned == 'name_sn') {
      return 'name_shona';
    }

    // Ndebele name aliases
    if (cleaned == 'ndebele' ||
        cleaned == 'ndebele_name' ||
        cleaned == 'name_ndebele' ||
        cleaned == 'name_nd') {
      return 'name_ndebele';
    }

    // Botanical / scientific name aliases
    if (cleaned == 'scientific_name' ||
        cleaned == 'botanical_name' ||
        cleaned == 'species' ||
        cleaned == 'binomial_name') {
      return 'scientific_name';
    }

    // Parts used aliases
    if (cleaned == 'part_used' ||
        cleaned == 'parts_used' ||
        cleaned == 'plant_parts_used') {
      return 'parts_used';
    }

    // Exotic origin status aliases
    if (cleaned == 'exotic_to_zimbabwe' ||
        cleaned == 'exotic' ||
        cleaned == 'exotic_status' ||
        cleaned == 'origin') {
      return 'exotic_status';
    }

    // Traditional Medicinal Uses aliases
    if (cleaned == 'traditional_use' ||
        cleaned == 'traditional_uses' ||
        cleaned == 'traditional_use_ailments_treated' ||
        cleaned == 'ailments_treated' ||
        cleaned == 'medicinal_uses' ||
        cleaned == 'uses') {
      return 'traditional_uses';
    }

    // Ailment categories
    if (cleaned == 'ailment_categories' ||
        cleaned == 'ailment_category' ||
        cleaned == 'categories' ||
        cleaned == 'body_systems') {
      return 'ailment_categories';
    }

    // Caution / safety warnings
    if (cleaned == 'caution' ||
        cleaned == 'cautions' ||
        cleaned == 'warning' ||
        cleaned == 'warnings' ||
        cleaned == 'precautions' ||
        cleaned == 'toxicity') {
      return 'caution';
    }

    // Bibliographic source
    if (cleaned == 'source' ||
        cleaned == 'sources' ||
        cleaned == 'reference' ||
        cleaned == 'references' ||
        cleaned == 'citation' ||
        cleaned == 'citations') {
      return 'source';
    }

    // Other uses & general notes
    if (cleaned == 'other_uses_notes' ||
        cleaned == 'other_uses_and_notes' ||
        cleaned == 'other_uses' ||
        cleaned == 'notes') {
      return 'other_uses_notes';
    }

    return cleaned;
  }

  static ParsedHerbImportRow _buildImportRow(
    Map<String, String> row,
    int rowNumber,
    String? currentUserId,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    var nameEn = row['common_name_en'] ?? row['name_en'] ?? '';
    final rawNameSn = row['name_shona'] ?? row['name_sn'];
    final nameSn = (rawNameSn != null && rawNameSn.trim().toLowerCase() != 'not found')
        ? rawNameSn.trim()
        : null;

    final rawNameNd = row['name_ndebele'] ?? row['name_nd'];
    final nameNd = (rawNameNd != null &&
            rawNameNd.trim().toLowerCase() != 'not found' &&
            rawNameNd.trim().toLowerCase() != 'none')
        ? rawNameNd.trim()
        : null;

    final rawScientific = row['scientific_name'];
    final scientificName = (rawScientific != null &&
            rawScientific.trim().toLowerCase() != 'not yet identified' &&
            rawScientific.trim().toLowerCase() != 'unknown')
        ? rawScientific.trim()
        : null;

    // Handle Zimbabwean herbs that have no common English name
    final isGenericEn = nameEn.trim().isEmpty ||
        nameEn.trim().toLowerCase() == 'no widely used english name' ||
        nameEn.trim().toLowerCase() == 'not found' ||
        nameEn.trim().toLowerCase() == 'none';

    if (isGenericEn) {
      if (nameSn != null && nameSn.isNotEmpty) {
        nameEn = nameSn;
      } else if (scientificName != null && scientificName.isNotEmpty) {
        nameEn = scientificName;
      }
    }

    // Mandatory validation
    if (nameEn.isEmpty) {
      errors.add('Missing English/Common Name');
    }
    if (scientificName == null || scientificName.isEmpty) {
      warnings.add('No scientific name provided');
    }

    final rawFamily = row['family'];
    final family = (rawFamily != null &&
            rawFamily.trim().toLowerCase() != 'not yet identified')
        ? rawFamily.trim()
        : null;

    final rawGrowthHabit = row['growth_habit'];
    final growthHabit = (rawGrowthHabit != null &&
            rawGrowthHabit.trim().toLowerCase() != 'not yet identified')
        ? rawGrowthHabit.trim()
        : null;

    final placesFound = row['places_found'] ?? row['distribution'];

    // Map Exotic Status (handles "Yes" / "No" / "Unknown" / "Indigenous")
    var exoticStatus = row['exotic_status'] ?? 'Indigenous';
    final lowerExotic = exoticStatus.trim().toLowerCase();
    if (lowerExotic == 'no' || lowerExotic == 'indigenous') {
      exoticStatus = 'Indigenous';
    } else if (lowerExotic == 'yes' ||
        lowerExotic.contains('exotic') ||
        lowerExotic.contains('cultivated')) {
      exoticStatus = 'Exotic / Cultivated';
    } else if (lowerExotic == 'unknown') {
      exoticStatus = 'Indigenous';
    }

    // Parts used parsing
    final partsUsedRaw = row['parts_used'];
    final partsUsed = (partsUsedRaw != null &&
            partsUsedRaw.isNotEmpty &&
            partsUsedRaw.trim().toLowerCase() != 'not specified')
        ? partsUsedRaw
            .split(RegExp(r'[,;/|]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s.toLowerCase() != 'not specified')
            .toList()
        : <String>[];

    // Caution parsing
    final rawCaution = row['caution'];
    final caution = (rawCaution != null &&
            rawCaution.trim().isNotEmpty &&
            rawCaution.trim().toLowerCase() != 'no specific warning recorded' &&
            rawCaution.trim().toLowerCase() != 'none')
        ? rawCaution.trim()
        : null;

    // Source parsing
    final rawSource = row['source'];
    final source =
        (rawSource != null && rawSource.trim().isNotEmpty) ? rawSource.trim() : null;

    // Other uses & notes parsing
    final rawOtherUses = row['other_uses_notes'] ?? row['other_uses'];
    final otherUsesNotes = (rawOtherUses != null &&
            rawOtherUses.trim().isNotEmpty &&
            rawOtherUses.trim().toLowerCase() != 'none recorded' &&
            rawOtherUses.trim().toLowerCase() != 'none')
        ? rawOtherUses.trim()
        : null;

    // Description & Traditional Medicinal Uses mapping
    var description = row['description'];
    final traditionalUses = row['traditional_uses'];
    final ailmentCategories = row['ailment_categories'];
    if (description == null || description.trim().isEmpty) {
      final buffer = StringBuffer();
      if (traditionalUses != null && traditionalUses.trim().isNotEmpty) {
        buffer.write(traditionalUses.trim());
      }
      if (ailmentCategories != null && ailmentCategories.trim().isNotEmpty) {
        if (buffer.isNotEmpty) buffer.write('\n\nAilment Categories: ');
        buffer.write(ailmentCategories.trim());
      }
      if (buffer.isNotEmpty) {
        description = buffer.toString();
      }
    }

    final herbId = _uuid.v4();

    // Parse other traditional uses
    final otherUses = <HerbOtherUseModel>[];
    void addUse(String category, String? content, String defaultTitle) {
      if (content != null && content.trim().isNotEmpty) {
        otherUses.add(HerbOtherUseModel(
          id: _uuid.v4(),
          herbId: herbId,
          category: category,
          title: defaultTitle,
          description: content.trim(),
          createdBy: currentUserId,
          createdAt: DateTime.now(),
        ));
      }
    }

    addUse('food_nutrition', row['food_nutrition'], 'Food & Nutrition');
    addUse('construction_fencing', row['construction_fencing'],
        'Construction & Fencing');
    addUse('firewood', row['firewood'], 'Firewood & Fuel');
    addUse('cultural_spiritual', row['cultural_spiritual'],
        'Cultural & Spiritual');
    addUse('ritual', row['ritual'], 'Ritual Uses');
    addUse('crafts_tools', row['crafts_tools'], 'Crafts & Practical Tools');
    addUse('other', row['other_uses'], 'Other Traditional Use');

    final herb = HerbModel(
      id: herbId,
      nameEn: nameEn,
      nameSn: nameSn,
      nameNd: nameNd,
      scientificName: scientificName,
      family: family,
      growthHabit: growthHabit,
      partsUsed: partsUsed,
      placesFound: placesFound,
      exoticStatus: exoticStatus,
      description: description,
      caution: caution,
      source: source,
      otherUsesNotes: otherUsesNotes,
      createdBy: currentUserId,
      createdAt: DateTime.now(),
      otherUses: otherUses,
    );

    return ParsedHerbImportRow(
      rowNumber: rowNumber,
      herb: herb,
      otherUses: otherUses,
      warnings: warnings,
      errors: errors,
    );
  }
}
