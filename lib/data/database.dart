import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

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

class EntryWithGame {
  final Entry entry;
  final Game game;

  EntryWithGame(this.entry, this.game);
}

@DriftDatabase(tables: [Publishers, Games, Entries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  @override
  int get schemaVersion => 1;

  // Games
  Future<List<Game>> searchGames(String query) {
    return (select(games)..where((tbl) => tbl.name.contains(query))).get();
  }

  Future<List<Game>> getAllGames() => select(games).get();

  Future<int> addGame(GamesCompanion game) => into(games).insert(game);

  // Publishers
  Future<Publisher?> getPublisherById(int id) {
    return (select(publishers)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<List<Publisher>> getAllPublishers() => select(publishers).get();

  Future<int> addPublisher(PublishersCompanion publisher) =>
      into(publishers).insert(publisher, mode: InsertMode.insertOrIgnore);

  // Entries
  Future<int> addEntry(EntriesCompanion entry) => into(entries).insert(entry);

  Stream<List<Entry>> watchAllEntries() => select(entries).watch();

  Stream<List<EntryWithGame>> watchAllEntriesWithGame() {
    final query = select(entries).join([
      innerJoin(games, games.id.equalsExp(entries.gameId)),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return EntryWithGame(
          row.readTable(entries),
          row.readTable(games),
        );
      }).toList();
    });
  }

  // Data Seeding
  Future<void> seedInitialData() async {
    final existing = await (select(publishers)..limit(1)).get();
    if (existing.isNotEmpty) return; // Already seeded

    final mihoyo = await addPublisher(const PublishersCompanion(name: Value('米哈游 (miHoYo)')));
    final tencent = await addPublisher(const PublishersCompanion(name: Value('腾讯游戏 (Tencent)')));
    final netease = await addPublisher(const PublishersCompanion(name: Value('网易游戏 (NetEase)')));
    final steam = await addPublisher(const PublishersCompanion(name: Value('Steam')));

    // Mihoyo Games
    await addGame(GamesCompanion.insert(publisherId: mihoyo, name: '原神', category: 'Service'));
    await addGame(GamesCompanion.insert(publisherId: mihoyo, name: '崩坏：星穹铁道', category: 'Service'));
    await addGame(GamesCompanion.insert(publisherId: mihoyo, name: '绝区零', category: 'Service'));

    // Tencent Games
    await addGame(GamesCompanion.insert(publisherId: tencent, name: '王者荣耀', category: 'Service'));
    // NetEase
    await addGame(GamesCompanion.insert(publisherId: netease, name: '蛋仔派对', category: 'Service'));

    // Steam Example
    await addGame(GamesCompanion.insert(publisherId: steam, name: '黑神话：悟空', category: 'Library'));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'game_accounting.db'));
    return NativeDatabase(file);
  });
}
