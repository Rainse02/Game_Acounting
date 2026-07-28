import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_accounting_pro/data/backup_service.dart';
import 'package:game_accounting_pro/data/csv_service.dart';
import 'package:game_accounting_pro/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addSampleEntry({String game = '原神', double price = 30}) async {
    final publisher = await db.getOrCreatePublisher('米哈游');
    final g = await db.getOrCreateGame(publisher.id, game, Categories.service);
    return db.addEntry(EntriesCompanion.insert(
      gameId: g.id,
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

      final inserted =
          await CsvService.importEntries(db, parsed.entries);
      expect(inserted, 1);
      expect(await db.getAllEntryDetails(), hasLength(2));
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
      expect(await db.watchSetting(SettingKeys.monthlyBudget).first, '300');
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
