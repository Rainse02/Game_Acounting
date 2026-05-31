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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'game_accounting.db'));
    return NativeDatabase(file);
  });
}
