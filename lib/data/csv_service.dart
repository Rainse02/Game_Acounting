import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import 'database.dart';

/// A single row parsed from a CSV file, ready to be inserted.
class ParsedEntry {
  final DateTime date;
  final String category; // one of Categories.all
  final String publisher;
  final String game;
  final String item;
  final double price;
  final int quantity;
  final String note;

  /// Set by [markDuplicates] when an identical entry already exists.
  bool isDuplicate = false;

  ParsedEntry({
    required this.date,
    required this.category,
    required this.publisher,
    required this.game,
    required this.item,
    required this.price,
    required this.quantity,
    required this.note,
  });

  double get total => price * quantity;

  /// Key used for duplicate detection.
  String get dedupeKey =>
      '${date.year}-${date.month}-${date.day}|$game|$item|$price|$quantity';
}

/// A row that could not be parsed, with the reason.
class RowIssue {
  final int rowNumber; // 1-based, including the header row
  final String message;

  RowIssue(this.rowNumber, this.message);
}

/// Supported CSV layouts.
enum CsvFormat {
  /// v2 unified format and the v1 in-app export (header-name based).
  headered,

  /// Export of the legacy Python app: 用户,日期,厂商,游戏,项目,单价,数量,总额,备注
  legacyPython,
}

class CsvParseResult {
  final CsvFormat format;
  final List<ParsedEntry> entries;
  final List<RowIssue> issues;

  CsvParseResult(this.format, this.entries, this.issues);
}

class CsvFormatException implements Exception {
  final String message;
  CsvFormatException(this.message);

  @override
  String toString() => message;
}

/// Parses and serializes ledger CSV files.
///
/// Export always writes the canonical header below. Import is header-driven
/// and accepts the canonical format, the old in-app export format and the
/// legacy Python export, so any file the app ever produced can be re-imported
/// without losing dates or categories.
class CsvService {
  static const List<String> canonicalHeader = [
    '日期', '分类', '厂商', '游戏', '项目', '单价', '数量', '总额', '备注', // Date, Category, Publisher, Game, Item, Price, Qty, Total, Note
  ];

  // Recognized header spellings (lower-cased) per logical column.
  static const Map<String, List<String>> _headerAliases = {
    'date': ['日期', 'date'],
    'category': ['分类', '类型', 'category'],
    'publisher': ['厂商', '发行商', 'publisher'],
    'game': ['游戏', 'game'],
    'item': ['项目', '项目名称', 'item'],
    'price': ['单价', '价格', 'price', 'unit price'],
    'quantity': ['数量', 'quantity', 'qty'],
    'note': ['备注', 'note', 'notes'],
  };

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  /// Serializes [details] to CSV text. A UTF-8 BOM is prepended so that Excel
  /// opens Chinese text correctly.
  static String exportCsv(List<EntryDetail> details) {
    final rows = <List<dynamic>>[List<dynamic>.from(canonicalHeader)];
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (final d in details) {
      rows.add([
        dateFormat.format(d.entry.date),
        d.game.category,
        d.publisher.name,
        d.game.name,
        d.entry.itemName,
        d.entry.price,
        d.entry.quantity,
        d.total,
        d.entry.note ?? '',
      ]);
    }

    return '\ufeff${const ListToCsvConverter().convert(rows)}';
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  /// Parses CSV [content]. Throws [CsvFormatException] when the layout cannot
  /// be recognized; individual bad rows are reported via [CsvParseResult.issues]
  /// instead of aborting the whole import.
  static CsvParseResult parse(String content) {
    // Strip BOM and normalize line endings.
    var text = content;
    if (text.startsWith('\ufeff')) text = text.substring(1);
    text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(text);

    if (rows.isEmpty) {
      throw CsvFormatException('empty file');
    }

    final header =
        rows.first.map((c) => c.toString().trim().toLowerCase()).toList();

    if (header.isNotEmpty && header.first == '用户') {
      return _parseLegacyPython(rows);
    }

    final columns = _mapHeader(header);
    if (columns == null) {
      throw CsvFormatException(
          'unrecognized header: ${rows.first.join(', ')}');
    }
    return _parseHeadered(rows, columns);
  }

  /// Maps logical column name -> index, or null if this is not a valid header.
  static Map<String, int>? _mapHeader(List<String> header) {
    final result = <String, int>{};
    _headerAliases.forEach((logical, aliases) {
      for (var i = 0; i < header.length; i++) {
        if (aliases.contains(header[i])) {
          result[logical] = i;
          break;
        }
      }
    });
    // date, game and item are the minimum required columns.
    if (!result.containsKey('date') ||
        !result.containsKey('game') ||
        !result.containsKey('item')) {
      return null;
    }
    return result;
  }

  static CsvParseResult _parseHeadered(
      List<List<dynamic>> rows, Map<String, int> col) {
    final entries = <ParsedEntry>[];
    final issues = <RowIssue>[];

    String cell(List<dynamic> row, String logical) {
      final index = col[logical];
      if (index == null || index >= row.length) return '';
      return row[index].toString().trim();
    }

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) {
        continue;
      }
      final rowNumber = i + 1;

      final dateText = cell(row, 'date');
      final date = parseDate(dateText);
      if (date == null) {
        issues.add(RowIssue(rowNumber, 'invalid date "$dateText"'));
        continue;
      }

      final game = cell(row, 'game');
      final item = cell(row, 'item');
      if (game.isEmpty || item.isEmpty) {
        issues.add(RowIssue(rowNumber, 'missing game or item name'));
        continue;
      }

      final priceText = cell(row, 'price');
      final price = parseAmount(priceText);
      if (price == null) {
        issues.add(RowIssue(rowNumber, 'invalid price "$priceText"'));
        continue;
      }

      final quantity = int.tryParse(cell(row, 'quantity')) ?? 1;
      final publisher = cell(row, 'publisher');

      entries.add(ParsedEntry(
        date: date,
        category: normalizeCategory(cell(row, 'category')),
        publisher: publisher.isEmpty ? 'Unknown' : publisher,
        game: game,
        item: item,
        price: price,
        quantity: quantity < 1 ? 1 : quantity,
        note: cell(row, 'note'),
      ));
    }

    return CsvParseResult(CsvFormat.headered, entries, issues);
  }

  /// 用户,日期,厂商,游戏,项目,单价,数量,总额,备注
  static CsvParseResult _parseLegacyPython(List<List<dynamic>> rows) {
    final entries = <ParsedEntry>[];
    final issues = <RowIssue>[];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) {
        continue;
      }
      final rowNumber = i + 1;
      if (row.length < 7) {
        issues.add(RowIssue(rowNumber, 'expected at least 7 columns'));
        continue;
      }

      String at(int index) =>
          index < row.length ? row[index].toString().trim() : '';

      final date = parseDate(at(1));
      if (date == null) {
        issues.add(RowIssue(rowNumber, 'invalid date "${at(1)}"'));
        continue;
      }
      final game = at(3);
      final item = at(4);
      if (game.isEmpty || item.isEmpty) {
        issues.add(RowIssue(rowNumber, 'missing game or item name'));
        continue;
      }
      final price = parseAmount(at(5));
      if (price == null) {
        issues.add(RowIssue(rowNumber, 'invalid price "${at(5)}"'));
        continue;
      }
      final quantity = int.tryParse(at(6)) ?? 1;

      entries.add(ParsedEntry(
        date: date,
        category: Categories.service, // legacy data had no category column
        publisher: at(2).isEmpty ? 'Unknown' : at(2),
        game: game,
        item: item,
        price: price,
        quantity: quantity < 1 ? 1 : quantity,
        note: at(8),
      ));
    }

    return CsvParseResult(CsvFormat.legacyPython, entries, issues);
  }

  // ---------------------------------------------------------------------------
  // Field helpers (public for tests)
  // ---------------------------------------------------------------------------

  static DateTime? parseDate(String text) {
    if (text.isEmpty) return null;
    final direct = DateTime.tryParse(text);
    if (direct != null) return direct;

    // Accept 2024/1/5, 2024.1.5, 2024-1-5
    final match =
        RegExp(r'^(\d{4})[./-](\d{1,2})[./-](\d{1,2})').firstMatch(text);
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  static double? parseAmount(String text) {
    final cleaned = text
        .replaceAll('¥', '')
        .replaceAll('￥', '')
        .replaceAll(',', '')
        .replaceAll(' ', '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Maps any recognized category spelling to a canonical key.
  static String normalizeCategory(String raw) {
    final value = raw.trim().toLowerCase();
    const libraryAliases = ['library', '买断', '单机', '单机/买断', 'buy-to-play'];
    const serviceAliases = ['service', '内购', '网游', '网游/内购', 'in-app'];
    const hardwareAliases = ['hardware', '相关', '外设', '游戏相关', 'peripheral'];

    if (libraryAliases.contains(value)) return Categories.library;
    if (serviceAliases.contains(value)) return Categories.service;
    if (hardwareAliases.contains(value)) return Categories.hardware;
    return Categories.service;
  }

  /// Flags entries in [parsed] that already exist in [existing].
  static void markDuplicates(
      List<ParsedEntry> parsed, List<EntryDetail> existing) {
    final existingKeys = existing.map((d) {
      final e = d.entry;
      return '${e.date.year}-${e.date.month}-${e.date.day}'
          '|${d.game.name}|${e.itemName}|${e.price}|${e.quantity}';
    }).toSet();

    for (final p in parsed) {
      p.isDuplicate = existingKeys.contains(p.dedupeKey);
    }
  }

  // ---------------------------------------------------------------------------
  // Database import
  // ---------------------------------------------------------------------------

  /// Inserts [toImport] into [db] inside a single transaction.
  /// Returns the number of entries actually inserted.
  static Future<int> importEntries(
    AppDatabase db,
    List<ParsedEntry> toImport, {
    bool skipDuplicates = true,
  }) async {
    var inserted = 0;
    await db.transaction(() async {
      for (final p in toImport) {
        if (skipDuplicates && p.isDuplicate) continue;

        final publisher = await db.getOrCreatePublisher(p.publisher);
        final game =
            await db.getOrCreateGame(publisher.id, p.game, p.category);

        await db.addEntry(EntriesCompanion.insert(
          gameId: game.id,
          date: p.date,
          itemName: p.item,
          price: p.price,
          quantity: Value(p.quantity),
          note: Value(p.note.isEmpty ? null : p.note),
        ));
        inserted++;
      }
    });
    return inserted;
  }
}
