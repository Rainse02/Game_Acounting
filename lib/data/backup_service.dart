import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

/// Thrown when a backup file cannot be parsed or has an unsupported version.
class BackupFormatException implements Exception {
  final String message;
  BackupFormatException(this.message);

  @override
  String toString() => message;
}

/// In-memory representation of a parsed backup file.
class BackupData {
  final int version;
  final DateTime? exportedAt;
  final List<Map<String, dynamic>> publishers;
  final List<Map<String, dynamic>> games;
  final List<Map<String, dynamic>> entries;
  final Map<String, String> settings;

  BackupData({
    required this.version,
    required this.exportedAt,
    required this.publishers,
    required this.games,
    required this.entries,
    required this.settings,
  });
}

/// Lossless JSON backup and restore of the whole database, including the
/// publisher/game relations that a flat CSV cannot represent.
class BackupService {
  static const int currentVersion = 1;

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  static Future<String> exportJson(AppDatabase db) async {
    final publishers = await db.getAllPublishers();
    final games = await db.getAllGames();
    final entries = await db.select(db.entries).get();
    final settings = await db.select(db.settings).get();

    final payload = <String, dynamic>{
      'app': 'game_accounting_pro',
      'version': currentVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'publishers': [
        for (final p in publishers)
          {'id': p.id, 'name': p.name, 'iconPath': p.iconPath},
      ],
      'games': [
        for (final g in games)
          {
            'id': g.id,
            'publisherId': g.publisherId,
            'name': g.name,
            'category': g.category,
            'iconPath': g.iconPath,
          },
      ],
      'entries': [
        for (final e in entries)
          {
            'id': e.id,
            'gameId': e.gameId,
            'date': e.date.toIso8601String(),
            'itemName': e.itemName,
            'price': e.price,
            'quantity': e.quantity,
            'note': e.note,
          },
      ],
      'settings': {for (final s in settings) s.key: s.value},
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  // ---------------------------------------------------------------------------
  // Parse + validate
  // ---------------------------------------------------------------------------

  static BackupData parse(String content) {
    dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      throw BackupFormatException('not a valid JSON file');
    }
    if (decoded is! Map<String, dynamic>) {
      throw BackupFormatException('unexpected JSON structure');
    }
    if (decoded['app'] != 'game_accounting_pro') {
      throw BackupFormatException('not a Game Ledger backup file');
    }
    final version = decoded['version'];
    if (version is! int || version < 1 || version > currentVersion) {
      throw BackupFormatException('unsupported backup version: $version');
    }

    List<Map<String, dynamic>> listOf(String key) {
      final raw = decoded[key];
      if (raw is! List) {
        throw BackupFormatException('missing "$key" section');
      }
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    final rawSettings = decoded['settings'];
    final settings = <String, String>{};
    if (rawSettings is Map) {
      rawSettings.forEach((k, v) => settings[k.toString()] = v.toString());
    }

    return BackupData(
      version: version,
      exportedAt: DateTime.tryParse(decoded['exportedAt']?.toString() ?? ''),
      publishers: listOf('publishers'),
      games: listOf('games'),
      entries: listOf('entries'),
      settings: settings,
    );
  }

  // ---------------------------------------------------------------------------
  // Restore
  // ---------------------------------------------------------------------------

  /// Replaces ALL current data with the contents of [data], in one transaction.
  /// Returns the number of restored entries.
  static Future<int> restore(AppDatabase db, BackupData data) async {
    var restored = 0;
    await db.transaction(() async {
      await db.delete(db.entries).go();
      await db.delete(db.games).go();
      await db.delete(db.publishers).go();

      for (final p in data.publishers) {
        await db.into(db.publishers).insert(PublishersCompanion(
              id: Value(p['id'] as int),
              name: Value(p['name'] as String),
              iconPath: Value(p['iconPath'] as String?),
            ));
      }

      for (final g in data.games) {
        await db.into(db.games).insert(GamesCompanion(
              id: Value(g['id'] as int),
              publisherId: Value(g['publisherId'] as int),
              name: Value(g['name'] as String),
              category: Value(g['category'] as String? ?? Categories.service),
              iconPath: Value(g['iconPath'] as String?),
            ));
      }

      for (final e in data.entries) {
        final date = DateTime.tryParse(e['date']?.toString() ?? '');
        if (date == null) continue;
        await db.into(db.entries).insert(EntriesCompanion(
              id: Value(e['id'] as int),
              gameId: Value(e['gameId'] as int),
              date: Value(date),
              itemName: Value(e['itemName'] as String),
              price: Value((e['price'] as num).toDouble()),
              quantity: Value(e['quantity'] as int? ?? 1),
              note: Value(e['note'] as String?),
            ));
        restored++;
      }

      for (final s in data.settings.entries) {
        await db.setSetting(s.key, s.value);
      }
    });
    return restored;
  }
}
