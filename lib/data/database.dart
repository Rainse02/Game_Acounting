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
  TextColumn get category =>
      text().withDefault(const Constant(Categories.service))();
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
  String get category => entry.category;
}

/// A unique game/publisher pair shown by autocomplete fields.
class GameSuggestion {
  final Game game;
  final Publisher publisher;

  const GameSuggestion(this.game, this.publisher);
}

class CatalogMergeResult {
  final int publishersMerged;
  final int gamesMerged;

  const CatalogMergeResult({
    required this.publishersMerged,
    required this.gamesMerged,
  });
}

/// Removes invisible/duplicate spacing while retaining the user's casing.
String cleanCatalogName(String value) => value
    .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
    .replaceAll('\u3000', ' ')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');

/// Comparison key used for publisher names and publisher/game pairs.
String catalogNameKey(String value) => cleanCatalogName(value).toLowerCase();

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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createCatalogIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(settings);
          }
          if (from < 3) {
            await m.addColumn(entries, entries.category);
            await customStatement('''
              UPDATE entries
              SET category = COALESCE(
                (SELECT games.category
                 FROM games
                 WHERE games.id = entries.game_id),
                '${Categories.service}'
              )
            ''');
            await _mergeDuplicateCatalog();
            await _createCatalogIndexes();
          }
        },
        beforeOpen: (_) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await _createCatalogIndexes();
        },
      );

  Future<void> _createCatalogIndexes() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS publishers_normalized_name_unique
      ON publishers(name COLLATE NOCASE)
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS games_publisher_name_unique
      ON games(publisher_id, name COLLATE NOCASE)
    ''');
  }

  // ---------------------------------------------------------------------------
  // Games
  // ---------------------------------------------------------------------------

  Future<List<GameSuggestion>> searchGameSuggestions(String query) async {
    final queryKey = catalogNameKey(query);
    final joined = select(games).join([
      innerJoin(publishers, publishers.id.equalsExp(games.publisherId)),
    ]);
    final rows = await joined.get();
    final suggestions = rows
        .map((row) => GameSuggestion(
              row.readTable(games),
              row.readTable(publishers),
            ))
        .where((suggestion) =>
            catalogNameKey(suggestion.game.name).contains(queryKey) ||
            catalogNameKey(suggestion.publisher.name).contains(queryKey))
        .toList();
    suggestions.sort((a, b) {
      final byGame =
          catalogNameKey(a.game.name).compareTo(catalogNameKey(b.game.name));
      if (byGame != 0) return byGame;
      return catalogNameKey(a.publisher.name)
          .compareTo(catalogNameKey(b.publisher.name));
    });
    return suggestions;
  }

  Future<List<Game>> searchGames(String query) async =>
      (await searchGameSuggestions(query)).map((item) => item.game).toList();

  Future<List<Game>> getAllGames() => select(games).get();

  Future<int> addGame(GamesCompanion game) => into(games).insert(game);

  Future<int> updateGame(int id, GamesCompanion game) {
    return (update(games)..where((t) => t.id.equals(id))).write(game);
  }

  /// Finds the canonical publisher/game pair, creating it when missing.
  ///
  /// [category] is only the default for a newly created game. Categories of
  /// existing ledger entries are stored on those entries and are never changed
  /// through this method.
  Future<Game> getOrCreateGame(
      int publisherId, String name, String category) async {
    final cleanedName = cleanCatalogName(name);
    if (cleanedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Game name cannot be empty');
    }

    final existingForPublisher = await (select(games)
          ..where((t) => t.publisherId.equals(publisherId)))
        .get();
    final key = catalogNameKey(cleanedName);
    for (final existing in existingForPublisher) {
      if (catalogNameKey(existing.name) == key) {
        return existing;
      }
    }

    final id = await into(games).insert(GamesCompanion.insert(
      publisherId: publisherId,
      name: cleanedName,
      category: category.isEmpty ? Categories.service : category,
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
    final cleanedName = cleanCatalogName(name);
    if (cleanedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Publisher name cannot be empty');
    }

    final key = catalogNameKey(cleanedName);
    final allPublishers = await getAllPublishers();
    for (final existing in allPublishers) {
      if (catalogNameKey(existing.name) == key) return existing;
    }

    final id = await into(publishers)
        .insert(PublishersCompanion.insert(name: cleanedName));
    return (select(publishers)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Merges historical pseudo-duplicates and rewires entries to one canonical
  /// publisher/game pair. The lowest id is retained for stable references.
  Future<CatalogMergeResult> mergeDuplicateCatalog() async {
    final result = await transaction(_mergeDuplicateCatalog);
    await _createCatalogIndexes();
    return result;
  }

  Future<CatalogMergeResult> _mergeDuplicateCatalog() async {
    final publisherRows = await (select(publishers)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final publisherSurvivors = <String, Publisher>{};
    final publisherTargetById = <int, int>{};
    var publishersMerged = 0;

    for (final publisher in publisherRows) {
      final key = catalogNameKey(publisher.name);
      final survivor = publisherSurvivors[key];
      if (survivor == null) {
        publisherSurvivors[key] = publisher;
        publisherTargetById[publisher.id] = publisher.id;
      } else {
        publisherTargetById[publisher.id] = survivor.id;
        publishersMerged++;
      }
    }

    final gameRows =
        await (select(games)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final gameSurvivors = <String, Game>{};
    final gameTargetById = <int, int>{};
    final resolvedPublisherByGameId = <int, int>{};
    var gamesMerged = 0;

    for (final game in gameRows) {
      final publisherId =
          publisherTargetById[game.publisherId] ?? game.publisherId;
      final key = '$publisherId\u0000${catalogNameKey(game.name)}';
      final survivor = gameSurvivors[key];
      if (survivor == null) {
        gameSurvivors[key] = game;
        gameTargetById[game.id] = game.id;
        resolvedPublisherByGameId[game.id] = publisherId;
      } else {
        gameTargetById[game.id] = survivor.id;
        gamesMerged++;
      }
    }

    for (final game in gameRows) {
      final targetId = gameTargetById[game.id]!;
      if (targetId == game.id) continue;
      await (update(entries)..where((t) => t.gameId.equals(game.id))).write(
        EntriesCompanion(gameId: Value(targetId)),
      );
    }

    for (final game in gameRows) {
      if (gameTargetById[game.id] != game.id) {
        await (delete(games)..where((t) => t.id.equals(game.id))).go();
      }
    }

    for (final game in gameRows) {
      if (gameTargetById[game.id] != game.id) continue;
      await (update(games)..where((t) => t.id.equals(game.id))).write(
        GamesCompanion(
          publisherId: Value(resolvedPublisherByGameId[game.id]!),
          name: Value(cleanCatalogName(game.name)),
        ),
      );
    }

    for (final publisher in publisherRows) {
      if (publisherTargetById[publisher.id] != publisher.id) {
        await (delete(publishers)..where((t) => t.id.equals(publisher.id)))
            .go();
      }
    }

    for (final publisher in publisherRows) {
      if (publisherTargetById[publisher.id] != publisher.id) continue;
      await (update(publishers)..where((t) => t.id.equals(publisher.id))).write(
        PublishersCompanion(name: Value(cleanCatalogName(publisher.name))),
      );
    }

    return CatalogMergeResult(
      publishersMerged: publishersMerged,
      gamesMerged: gamesMerged,
    );
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
