import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Category keys stored in the database. UI labels are localized separately.
class Categories {
  static const library = 'Library'; // buy-to-play games
  static const service = 'Service'; // in-app purchases / subscriptions
  static const hardware = 'Hardware'; // peripherals & related
  static const all = <String>[library, service, hardware];
}

/// Well-known keys for the [Settings] table.
class SettingKeys {
  static const monthlyBudget = 'monthly_budget';
}

class Publishers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get iconPath => text().nullable()();
}

class Games extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get publisherId => integer().references(Publishers, #id)();
  TextColumn get name => text()();
  TextColumn get category => text()(); // 'Library', 'Service', 'Hardware'
  TextColumn get iconPath => text().nullable()();
}

class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameId => integer().references(Games, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get itemName => text()();
  RealColumn get price => real()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get note => text().nullable()();
}

/// Simple key-value store for app settings (e.g. the monthly budget).
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// An entry joined with its game and publisher.
class EntryDetail {
  final Entry entry;
  final Game game;
  final Publisher publisher;

  EntryDetail(this.entry, this.game, this.publisher);

  double get total => entry.price * entry.quantity;
}

/// Kept for backwards compatibility with the old UI layer.
class EntryWithGame {
  final Entry entry;
  final Game game;

  EntryWithGame(this.entry, this.game);
}

@DriftDatabase(tables: [Publishers, Games, Entries, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Used by tests to run against an in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(settings);
          }
        },
      );

  // ---------------------------------------------------------------------------
  // Games
  // ---------------------------------------------------------------------------

  Future<List<Game>> searchGames(String query) {
    return (select(games)..where((tbl) => tbl.name.contains(query))).get();
  }

  Future<List<Game>> getAllGames() => select(games).get();

  Future<int> addGame(GamesCompanion game) => into(games).insert(game);

  Future<int> updateGame(int id, GamesCompanion game) {
    return (update(games)..where((t) => t.id.equals(id))).write(game);
  }

  /// Finds a game by publisher + name, creating it when missing
  /// or updating its category when modified.
  Future<Game> getOrCreateGame(
      int publisherId, String name, String category) async {
    final existing = await (select(games)
          ..where((t) => t.publisherId.equals(publisherId) & t.name.equals(name)))
        .getSingleOrNull();
    if (existing != null) {
      if (category.isNotEmpty && existing.category != category) {
        await updateGame(
            existing.id, GamesCompanion(category: Value(category)));
        return (select(games)..where((t) => t.id.equals(existing.id)))
            .getSingle();
      }
      return existing;
    }

    final id = await into(games).insert(GamesCompanion.insert(
      publisherId: publisherId,
      name: name,
      category: category,
    ));
    return (select(games)..where((t) => t.id.equals(id))).getSingle();
  }

  // ---------------------------------------------------------------------------
  // Publishers
  // ---------------------------------------------------------------------------

  Future<Publisher?> getPublisherById(int id) {
    return (select(publishers)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<Publisher>> getAllPublishers() => select(publishers).get();

  Future<int> addPublisher(PublishersCompanion publisher) =>
      into(publishers).insert(publisher, mode: InsertMode.insertOrIgnore);

  Future<Publisher> getOrCreatePublisher(String name) async {
    final existing = await (select(publishers)
          ..where((t) => t.name.equals(name)))
        .getSingleOrNull();
    if (existing != null) return existing;

    final id =
        await into(publishers).insert(PublishersCompanion.insert(name: name));
    return (select(publishers)..where((t) => t.id.equals(id))).getSingle();
  }

  // ---------------------------------------------------------------------------
  // Entries
  // ---------------------------------------------------------------------------

  Future<int> addEntry(EntriesCompanion entry) => into(entries).insert(entry);

  /// Updates the given columns of an existing entry.
  Future<int> updateEntry(int id, EntriesCompanion entry) {
    return (update(entries)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<int> deleteEntry(Entry entry) => delete(entries).delete(entry);

  /// Re-inserts a previously deleted entry, keeping its original id.
  /// Used by the "undo delete" action.
  Future<void> restoreEntry(Entry entry) async {
    await into(entries)
        .insert(entry.toCompanion(false), mode: InsertMode.insertOrReplace);
  }

  Stream<List<Entry>> watchAllEntries() => select(entries).watch();

  /// Entries joined with game and publisher, newest first.
  Stream<List<EntryDetail>> watchAllEntryDetails() {
    final query = select(entries).join([
      innerJoin(games, games.id.equalsExp(entries.gameId)),
      innerJoin(publishers, publishers.id.equalsExp(games.publisherId)),
    ])
      ..orderBy([
        OrderingTerm.desc(entries.date),
        OrderingTerm.desc(entries.id),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return EntryDetail(
          row.readTable(entries),
          row.readTable(games),
          row.readTable(publishers),
        );
      }).toList();
    });
  }

  Future<List<EntryDetail>> getAllEntryDetails() =>
      watchAllEntryDetails().first;

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  Future<void> setSetting(String key, String value) async {
    await into(settings).insert(
      SettingsCompanion(key: Value(key), value: Value(value)),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> removeSetting(String key) async {
    await (delete(settings)..where((t) => t.key.equals(key))).go();
  }

  Stream<String?> watchSetting(String key) {
    return (select(settings)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  // ---------------------------------------------------------------------------
  // Bulk operations
  // ---------------------------------------------------------------------------

  /// Deletes all user data (entries, games, publishers) in one transaction.
  /// Settings are kept.
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(entries).go();
      await delete(games).go();
      await delete(publishers).go();
    });
  }

  // ---------------------------------------------------------------------------
  // Data seeding
  // ---------------------------------------------------------------------------

  Future<void> seedInitialData() async {
    final existing = await (select(publishers)..limit(1)).get();
    if (existing.isNotEmpty) return; // Already seeded

    final mihoyo = await addPublisher(
        const PublishersCompanion(name: Value('米哈游 (miHoYo)')));
    final tencent = await addPublisher(
        const PublishersCompanion(name: Value('腾讯游戏 (Tencent)')));
    final netease = await addPublisher(
        const PublishersCompanion(name: Value('网易游戏 (NetEase)')));
    final steam =
        await addPublisher(const PublishersCompanion(name: Value('Steam')));

    await addGame(GamesCompanion.insert(
        publisherId: mihoyo, name: '原神', category: Categories.service));
    await addGame(GamesCompanion.insert(
        publisherId: mihoyo, name: '崩坏：星穹铁道', category: Categories.service));
    await addGame(GamesCompanion.insert(
        publisherId: mihoyo, name: '绝区零', category: Categories.service));
    await addGame(GamesCompanion.insert(
        publisherId: tencent, name: '王者荣耀', category: Categories.service));
    await addGame(GamesCompanion.insert(
        publisherId: netease, name: '蛋仔派对', category: Categories.service));
    await addGame(GamesCompanion.insert(
        publisherId: steam, name: '黑神话：悟空', category: Categories.library));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'game_accounting.db'));
    return NativeDatabase(file);
  });
}
