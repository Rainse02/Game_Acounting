import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'database.dart';

class MigrationUtility {
  static Future<void> importFromCsv(File file, AppDatabase db) async {
    final input = file.openRead();
    final fields = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();

    // Skip header [用户, 日期, 厂商, 游戏, 项目, 单价, 数量, 总额, 备注]
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.isEmpty) continue;

      final pubName = row[2].toString().trim();
      final gameName = row[3].toString().trim();

      if (pubName.isEmpty || gameName.isEmpty) continue;

      // Upsert publisher
      // Since Drift's insertReturning with insertOrIgnore might return null if ignored,
      // we'll manually check/insert for better reliability in this migration context.
      var pub = await (db.select(db.publishers)..where((t) => t.name.equals(pubName))).getSingleOrNull();
      if (pub == null) {
        final pubId = await db.into(db.publishers).insert(
          PublishersCompanion.insert(name: pubName),
          mode: InsertMode.insertOrIgnore,
        );
        pub = await (db.select(db.publishers)..where((t) => t.id.equals(pubId))).getSingle();
      }

      // Upsert game
      var game = await (db.select(db.games)
        ..where((t) => t.publisherId.equals(pub!.id) & t.name.equals(gameName))).getSingleOrNull();
      if (game == null) {
        final gameId = await db.into(db.games).insert(
          GamesCompanion.insert(
            publisherId: pub.id,
            name: gameName,
            category: 'Service', // Default category
          ),
          mode: InsertMode.insertOrIgnore,
        );
        game = await (db.select(db.games)..where((t) => t.id.equals(gameId))).getSingle();
      }

      // Insert entry
      await db.into(db.entries).insert(EntriesCompanion.insert(
        gameId: game.id,
        date: DateTime.tryParse(row[1].toString()) ?? DateTime.now(),
        itemName: row[4].toString(),
        price: double.tryParse(row[5].toString()) ?? 0.0,
        quantity: Value(int.tryParse(row[6].toString()) ?? 1),
        note: Value(row[8].toString()),
      ));
    }
  }
}
