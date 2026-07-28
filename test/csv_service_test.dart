import 'package:flutter_test/flutter_test.dart';
import 'package:game_accounting_pro/data/csv_service.dart';
import 'package:game_accounting_pro/data/database.dart';

void main() {
  group('CsvService.parse', () {
    test('parses the canonical export format', () {
      const csv = '日期,分类,厂商,游戏,项目,单价,数量,总额,备注\r\n'
          '2025-03-01,Service,米哈游 (miHoYo),原神,月卡,30.0,1,30.0,首充\r\n'
          '2024-11-11,Library,Steam,黑神话:悟空,本体,268.0,1,268.0,\r\n';

      final result = CsvService.parse(csv);

      expect(result.format, CsvFormat.headered);
      expect(result.issues, isEmpty);
      expect(result.entries, hasLength(2));

      final first = result.entries.first;
      expect(first.date, DateTime(2025, 3, 1));
      expect(first.category, Categories.service);
      expect(first.publisher, '米哈游 (miHoYo)');
      expect(first.game, '原神');
      expect(first.item, '月卡');
      expect(first.price, 30.0);
      expect(first.quantity, 1);
      expect(first.note, '首充');
    });

    test('parses the old in-app export (translated categories, BOM)', () {
      const csv = '\ufeff日期,分类,厂商,游戏,项目,单价,数量,总额,备注\n'
          '2025-01-05,内购,腾讯游戏,王者荣耀,皮肤,64.0,2,128.0,\n'
          '2024-06-18,买断,Steam,艾尔登法环,本体,298.0,1,298.0,DLC待补\n';

      final result = CsvService.parse(csv);

      expect(result.issues, isEmpty);
      expect(result.entries, hasLength(2));
      expect(result.entries[0].category, Categories.service);
      expect(result.entries[0].quantity, 2);
      expect(result.entries[1].category, Categories.library);
      // The old export/import mismatch corrupted dates; the new parser
      // must preserve them.
      expect(result.entries[1].date, DateTime(2024, 6, 18));
    });

    test('parses the legacy Python export', () {
      const csv = '用户,日期,厂商,游戏,项目,单价,数量,总额,备注\n'
          'me,2023-09-30,网易游戏,蛋仔派对,盲盒,6.0,10,60.0,冲动消费\n';

      final result = CsvService.parse(csv);

      expect(result.format, CsvFormat.legacyPython);
      expect(result.entries, hasLength(1));
      final entry = result.entries.single;
      expect(entry.date, DateTime(2023, 9, 30));
      expect(entry.publisher, '网易游戏');
      expect(entry.game, '蛋仔派对');
      expect(entry.quantity, 10);
      expect(entry.note, '冲动消费');
      // Legacy data has no category column; defaults to Service.
      expect(entry.category, Categories.service);
    });

    test('collects bad rows as issues instead of failing the import', () {
      const csv = '日期,分类,厂商,游戏,项目,单价,数量,总额,备注\n'
          'not-a-date,Service,X,GameX,ItemX,10,1,10,\n'
          '2025-02-02,Service,X,GameX,ItemY,abc,1,0,\n'
          '2025-02-03,Service,X,GameX,ItemZ,15,1,15,\n';

      final result = CsvService.parse(csv);

      expect(result.entries, hasLength(1));
      expect(result.entries.single.item, 'ItemZ');
      expect(result.issues, hasLength(2));
      expect(result.issues[0].rowNumber, 2);
      expect(result.issues[1].rowNumber, 3);
    });

    test('rejects files with an unknown layout', () {
      expect(
        () => CsvService.parse('foo,bar\n1,2\n'),
        throwsA(isA<CsvFormatException>()),
      );
    });

    test('round-trips its own export', () {
      const csv = '日期,分类,厂商,游戏,项目,单价,数量,总额,备注\n'
          '2025-03-01,Service,米哈游 (miHoYo),原神,月卡,30.0,1,30.0,\n';
      final parsed = CsvService.parse(csv);

      // Simulated re-export of what was parsed must parse identically.
      final reParsed = CsvService.parse(
        '日期,分类,厂商,游戏,项目,单价,数量,总额,备注\n'
        '${[
          '2025-03-01',
          parsed.entries.single.category,
          parsed.entries.single.publisher,
          parsed.entries.single.game,
          parsed.entries.single.item,
          parsed.entries.single.price,
          parsed.entries.single.quantity,
          parsed.entries.single.total,
          parsed.entries.single.note,
        ].join(',')}\n',
      );

      expect(reParsed.entries.single.date, parsed.entries.single.date);
      expect(reParsed.entries.single.category, parsed.entries.single.category);
      expect(reParsed.entries.single.price, parsed.entries.single.price);
    });
  });

  group('field helpers', () {
    test('parseDate accepts common spellings', () {
      expect(CsvService.parseDate('2024-01-05'), DateTime(2024, 1, 5));
      expect(CsvService.parseDate('2024/1/5'), DateTime(2024, 1, 5));
      expect(CsvService.parseDate('2024.1.5'), DateTime(2024, 1, 5));
      expect(CsvService.parseDate('nope'), isNull);
      expect(CsvService.parseDate(''), isNull);
    });

    test('parseAmount strips currency symbols and separators', () {
      expect(CsvService.parseAmount('¥1,234.50'), 1234.50);
      expect(CsvService.parseAmount('￥30'), 30);
      expect(CsvService.parseAmount('abc'), isNull);
    });

    test('normalizeCategory maps all known spellings', () {
      expect(CsvService.normalizeCategory('Library'), Categories.library);
      expect(CsvService.normalizeCategory('买断'), Categories.library);
      expect(CsvService.normalizeCategory('内购'), Categories.service);
      expect(CsvService.normalizeCategory('service'), Categories.service);
      expect(CsvService.normalizeCategory('相关'), Categories.hardware);
      expect(CsvService.normalizeCategory('HARDWARE'), Categories.hardware);
      expect(CsvService.normalizeCategory('unknown'), Categories.service);
    });
  });
}
