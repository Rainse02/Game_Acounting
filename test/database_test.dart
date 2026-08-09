import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_accounting_pro/data/backup_service.dart';
import 'package:game_accounting_pro/data/csv_service.dart';
import 'package:game_accounting_pro/data/database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addSampleEntry({
    String game = '原神',
    String publisherName = '米哈游',
    String category = Categories.service,
    double price = 30,
  }) async {
    final publisher = await db.getOrCreatePublisher(publisherName);
    final g = await db.getOrCreateGame(publisher.id, game, category);
    return db.addEntry(EntriesCompanion.insert(
      gameId: g.id,
      category: Value(category),
      date: DateTime(2025, 3, 1),
      itemName: '月卡',
      price: price,
    ));
  }

  group('entries', () {
    test('add, update and delete', () async {
      final id = await addSampleEntry();

      var details = await db.getAllEntryDetails();
      expect(details, hasLength(1));
      expect(details.single.entry.price, 30);
      expect(details.single.publisher.name, '米哈游');

      await db.updateEntry(id, const EntriesCompanion(price: Value(68.0)));
      details = await db.getAllEntryDetails();
      expect(details.single.entry.price, 68.0);

      await db.deleteEntry(details.single.entry);
      details = await db.getAllEntryDetails();
      expect(details, isEmpty);
    });

    test('restoreEntry brings back a deleted entry with the same id', () async {
      await addSampleEntry();
      final detail = (await db.getAllEntryDetails()).single;

      await db.deleteEntry(detail.entry);
      expect(await db.getAllEntryDetails(), isEmpty);

      await db.restoreEntry(detail.entry);
      final restored = (await db.getAllEntryDetails()).single;
      expect(restored.entry.id, detail.entry.id);
      expect(restored.entry.itemName, detail.entry.itemName);
    });

    test('getOrCreate does not duplicate publishers or games', () async {
      await addSampleEntry();
      await addSampleEntry();

      expect(await db.getAllPublishers(), hasLength(1));
      expect(await db.getAllGames(), hasLength(1));
      expect(await db.getAllEntryDetails(), hasLength(2));
    });

    test('editing one entry category does not affect the same game history',
        () async {
      final publisher = await db.getOrCreatePublisher('米哈游');
      final game =
          await db.getOrCreateGame(publisher.id, '原神', Categories.service);
      final firstId = await addSampleEntry();
      final secondId = await addSampleEntry(price: 68);

      final resolved =
          await db.getOrCreateGame(publisher.id, '原神', Categories.library);
      expect(resolved.id, game.id);
      expect(resolved.category, Categories.service);

      await db.updateEntry(
        firstId,
        const EntriesCompanion(category: Value(Categories.library)),
      );

      final details = await db.getAllEntryDetails();
      expect(
        details.singleWhere((d) => d.entry.id == firstId).category,
        Categories.library,
      );
      expect(
        details.singleWhere((d) => d.entry.id == secondId).category,
        Categories.service,
      );
    });

    test('catalog names are normalized into one publisher/game pair', () async {
      final firstPublisher =
          await db.getOrCreatePublisher('  Valve   Corporation  ');
      final secondPublisher =
          await db.getOrCreatePublisher('valve corporation');
      final invisibleSpacedPublisher =
          await db.getOrCreatePublisher('\u200BValve Corporation\uFEFF');
      expect(secondPublisher.id, firstPublisher.id);
      expect(invisibleSpacedPublisher.id, firstPublisher.id);
      expect(firstPublisher.name, 'Valve Corporation');

      final firstGame = await db.getOrCreateGame(
        firstPublisher.id,
        ' Half-Life ',
        Categories.library,
      );
      final secondGame = await db.getOrCreateGame(
        secondPublisher.id,
        'half-life',
        Categories.service,
      );
      expect(secondGame.id, firstGame.id);
      expect(await db.getAllPublishers(), hasLength(1));
      expect(await db.getAllGames(), hasLength(1));
    });

    test('historical pseudo-duplicates merge without changing entry category',
        () async {
      await db.customStatement('DROP INDEX publishers_normalized_name_unique');
      await db.customStatement('DROP INDEX games_publisher_name_unique');

      final firstPublisherId = await db.into(db.publishers).insert(
            PublishersCompanion.insert(name: 'Valve'),
          );
      final duplicatePublisherId = await db.into(db.publishers).insert(
            PublishersCompanion.insert(name: ' valve  '),
          );
      final firstGameId = await db.into(db.games).insert(
            GamesCompanion.insert(
              publisherId: firstPublisherId,
              name: 'Half-Life',
              category: Categories.library,
            ),
          );
      final duplicateGameId = await db.into(db.games).insert(
            GamesCompanion.insert(
              publisherId: duplicatePublisherId,
              name: ' half-life ',
              category: Categories.service,
            ),
          );
      await db.addEntry(EntriesCompanion.insert(
        gameId: firstGameId,
        category: const Value(Categories.library),
        date: DateTime(2025, 1, 1),
        itemName: 'Game',
        price: 10,
      ));
      await db.addEntry(EntriesCompanion.insert(
        gameId: duplicateGameId,
        category: const Value(Categories.service),
        date: DateTime(2025, 2, 1),
        itemName: 'DLC',
        price: 5,
      ));

      final result = await db.mergeDuplicateCatalog();

      expect(result.publishersMerged, 1);
      expect(result.gamesMerged, 1);
      expect(await db.getAllPublishers(), hasLength(1));
      expect(await db.getAllGames(), hasLength(1));
      final details = await db.getAllEntryDetails();
      expect(details.map((detail) => detail.game.id).toSet(), hasLength(1));
      expect(
        details.map((detail) => detail.category).toSet(),
        {Categories.library, Categories.service},
      );
    });
  });

  group('migration', () {
    test('v2 data gains entry categories and canonical catalog pairs',
        () async {
      await db.close();
      final legacy = sqlite.sqlite3.openInMemory();
      legacy.execute('''
        CREATE TABLE publishers (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          icon_path TEXT
        );
        CREATE TABLE games (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          publisher_id INTEGER NOT NULL REFERENCES publishers(id),
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          icon_path TEXT
        );
        CREATE TABLE entries (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          game_id INTEGER NOT NULL REFERENCES games(id),
          date INTEGER NOT NULL,
          item_name TEXT NOT NULL,
          price REAL NOT NULL,
          quantity INTEGER NOT NULL DEFAULT 1,
          note TEXT
        );
        CREATE TABLE settings (
          key TEXT NOT NULL PRIMARY KEY,
          value TEXT NOT NULL
        );
      ''');
      legacy.execute("INSERT INTO publishers (id, name) VALUES (1, 'Valve')");
      legacy
          .execute("INSERT INTO publishers (id, name) VALUES (2, ' valve  ')");
      legacy.execute('''
        INSERT INTO games (id, publisher_id, name, category)
        VALUES (1, 1, 'Half-Life', 'Library')
      ''');
      legacy.execute('''
        INSERT INTO games (id, publisher_id, name, category)
        VALUES (2, 2, ' half-life ', 'Service')
      ''');
      legacy.execute('''
        INSERT INTO entries
          (id, game_id, date, item_name, price, quantity)
        VALUES (1, 1, 1735689600, 'Game', 10, 1)
      ''');
      legacy.execute('''
        INSERT INTO entries
          (id, game_id, date, item_name, price, quantity)
        VALUES (2, 2, 1738368000, 'DLC', 5, 1)
      ''');
      legacy.userVersion = 2;

      db = AppDatabase.forTesting(NativeDatabase.opened(legacy));
      final details = await db.getAllEntryDetails();

      expect(details, hasLength(2));
      expect(await db.getAllPublishers(), hasLength(1));
      expect(await db.getAllGames(), hasLength(1));
      expect(details.map((detail) => detail.game.id).toSet(), hasLength(1));
      expect(
        details.map((detail) => detail.category).toSet(),
        {Categories.library, Categories.service},
      );
      expect(legacy.userVersion, 3);
    });
  });

  group('settings', () {
    test('set, watch and remove', () async {
      await db.setSetting(SettingKeys.monthlyBudget, '300');
      expect(await db.watchSetting(SettingKeys.monthlyBudget).first, '300');

      await db.setSetting(SettingKeys.monthlyBudget, '500');
      expect(await db.watchSetting(SettingKeys.monthlyBudget).first, '500');

      await db.removeSetting(SettingKeys.monthlyBudget);
      expect(await db.watchSetting(SettingKeys.monthlyBudget).first, isNull);
    });
  });

  group('csv import', () {
    test('imports parsed rows and skips duplicates', () async {
      await addSampleEntry();
      final existing = await db.getAllEntryDetails();

      const csv = '日期,分类,厂商,游戏,项目,单价,数量,总额,备注\n'
          '2025-03-01,Service,米哈游,原神,月卡,30.0,1,30.0,\n' // duplicate
          '2025-04-01,Library,Steam,黑神话:悟空,本体,268.0,1,268.0,\n';
      final parsed = CsvService.parse(csv);
      CsvService.markDuplicates(parsed.entries, existing);

      expect(parsed.entries.where((e) => e.isDuplicate), hasLength(1));

      final inserted = await CsvService.importEntries(db, parsed.entries);
      expect(inserted, 1);
      expect(await db.getAllEntryDetails(), hasLength(2));
    });

    test('duplicate detection includes the publisher/game pair', () async {
      await addSampleEntry();
      final existing = await db.getAllEntryDetails();
      final parsed = [
        ParsedEntry(
          date: DateTime(2025, 3, 1),
          category: Categories.service,
          publisher: 'Another publisher',
          game: '原神',
          item: '月卡',
          price: 30,
          quantity: 1,
          note: '',
        ),
      ];

      CsvService.markDuplicates(parsed, existing);

      expect(parsed.single.isDuplicate, isFalse);
    });
  });

  group('json backup', () {
    test('export and restore round-trip', () async {
      await addSampleEntry();
      await db.setSetting(SettingKeys.monthlyBudget, '300');

      final json = await BackupService.exportJson(db);

      // Wreck the database, then restore.
      await db.clearAllData();
      expect(await db.getAllEntryDetails(), isEmpty);

      final data = BackupService.parse(json);
      final restored = await BackupService.restore(db, data);

      expect(restored, 1);
      final details = await db.getAllEntryDetails();
      expect(details, hasLength(1));
      expect(details.single.game.name, '原神');
      expect(details.single.publisher.name, '米哈游');
      expect(details.single.category, Categories.service);
      expect(await db.watchSetting(SettingKeys.monthlyBudget).first, '300');
    });

    test('restores v1 backups by deriving category from the game', () async {
      const legacyBackup = '''
      {
        "app": "game_accounting_pro",
        "version": 1,
        "exportedAt": "2025-03-01T00:00:00.000",
        "publishers": [
          {"id": 1, "name": "Valve", "iconPath": null}
        ],
        "games": [
          {
            "id": 1,
            "publisherId": 1,
            "name": "Half-Life",
            "category": "Library",
            "iconPath": null
          }
        ],
        "entries": [
          {
            "id": 1,
            "gameId": 1,
            "date": "2025-03-01T00:00:00.000",
            "itemName": "Game",
            "price": 10,
            "quantity": 1,
            "note": null
          }
        ],
        "settings": {}
      }
      ''';

      final restored =
          await BackupService.restore(db, BackupService.parse(legacyBackup));

      expect(restored, 1);
      expect(
        (await db.getAllEntryDetails()).single.category,
        Categories.library,
      );
    });

    test('rejects foreign JSON files', () {
      expect(
        () => BackupService.parse('{"hello": "world"}'),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => BackupService.parse('not json'),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });
}
