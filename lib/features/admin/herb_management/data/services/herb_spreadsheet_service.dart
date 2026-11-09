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
    'common_name_en',
    'scientific_name',
    'name_shona',
    'name_ndebele',
    'family',
    'growth_habit',
    'parts_used',
    'places_found',
    'exotic_status',
    'description',
    'caution',
    'source',
    'other_uses_notes',
    'food_nutrition',
    'construction_fencing',
    'firewood',
    'cultural_spiritual',
    'ritual',
    'crafts_tools',
    'other_uses',
  ];

  static const List<String> sampleRow = [
    'Fever Tea (Zumbani)',
    'Lippia javanica',
    'Zumbani',
    'Insuzwane',
    'Verbenaceae',
    'Shrub',
    'Leaves, Twigs',
    'Common across Zimbabwe in open grasslands, rocky slopes, and roadsides',
    'Indigenous',
    'Aromatic woody shrub with dense clusters of small white flowers.',
    'Avoid high doses during pregnancy; consult healthcare practitioner.',
    'Flora of Zimbabwe; Gelfand et al. (1985)',
    'Traditional steam cleanser, insect repellent, and herbal tea.',
    'Herbal tea beverage consumed hot or cold.',
    'Fresh branches used for pest repellent in granaries.',
    'Dry stems burn easily; used for kindling.',
    'Used as a body wash and steam cleanser for spiritual purification.',
    'Burned as incense during cultural cleansing rituals.',
    'Natural mosquito and insect repellent.',
    'Essential oil extraction for perfumes and soaps.',
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
    final cleaned =
        raw.trim().toLowerCase().replaceAll(RegExp(r'[\s\-]+'), '_');
    // Normalize aliases
    if (cleaned == 'english_name' ||
        cleaned == 'name' ||
        cleaned == 'common_name') {
      return 'common_name_en';
    }
    if (cleaned == 'distribution' ||
        cleaned == 'where_found' ||
        cleaned == 'location') {
      return 'places_found';
    }
    if (cleaned == 'shona' || cleaned == 'shona_name') return 'name_shona';
    if (cleaned == 'ndebele' || cleaned == 'ndebele_name') return 'name_ndebele';
    if (cleaned == 'botanical_name') return 'scientific_name';
    if (cleaned == 'caution' ||
        cleaned == 'cautions' ||
        cleaned == 'warning' ||
        cleaned == 'warnings' ||
        cleaned == 'precautions') {
      return 'caution';
    }
    if (cleaned == 'source' ||
        cleaned == 'sources' ||
        cleaned == 'reference' ||
        cleaned == 'references' ||
        cleaned == 'citation' ||
        cleaned == 'citations') {
      return 'source';
    }
    if (cleaned == 'other_uses_&_notes' ||
        cleaned == 'other_uses_and_notes' ||
        cleaned == 'other_uses_notes' ||
        cleaned == 'other_uses_notes_notes' ||
        cleaned == 'other_uses_&_notes' ||
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

    final nameEn = row['common_name_en'] ?? row['name_en'] ?? '';
    final scientificName = row['scientific_name'];
    final nameSn = row['name_shona'] ?? row['name_sn'];
    final nameNd = row['name_ndebele'] ?? row['name_nd'];
    final family = row['family'];
    final growthHabit = row['growth_habit'];
    final placesFound = row['places_found'] ?? row['distribution'];
    final exoticStatus = row['exotic_status'] ?? 'Indigenous';
    final description = row['description'];
    final caution = row['caution'];
    final source = row['source'];
    final otherUsesNotes = row['other_uses_notes'] ?? row['other_uses'];

    // Mandatory validation
    if (nameEn.isEmpty) {
      errors.add('Missing English/Common Name');
    }
    if (scientificName == null || scientificName.isEmpty) {
      warnings.add('No scientific name provided');
    }

    // Parts used parsing
    final partsUsedRaw = row['parts_used'];
    final partsUsed = (partsUsedRaw != null && partsUsedRaw.isNotEmpty)
        ? partsUsedRaw
            .split(RegExp(r'[,;/|]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];

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
