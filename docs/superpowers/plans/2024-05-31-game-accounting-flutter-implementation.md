# Game Accounting Pro Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone Windows and Android app for game accounting using Flutter, replacing the legacy Streamlit CSV system with a local SQLite database and smart search-first entry.

**Architecture:** Clean Architecture with a separate data layer for SQLite and CSV migration. Uses the `drift` package for type-safe database access and `provider` for state management.

**Tech Stack:** Flutter, Dart, SQLite (Drift), Path Provider, File Picker.

---

### Task 1: Project Scaffolding & Dependencies

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart`

- [ ] **Step 1: Initialize Flutter project and add dependencies**

Add these to `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  drift: ^2.16.0
  sqlite3_flutter_libs: ^0.5.20
  path_provider: ^2.1.3
  path: ^1.9.0
  provider: ^6.1.2
  file_picker: ^8.0.0
  intl: ^0.19.0
  fl_chart: ^0.67.0

dev_dependencies:
  drift_dev: ^2.16.0
  build_runner: ^2.4.9
```

- [ ] **Step 2: Create entry point**

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const GameAccountingApp());
}

class GameAccountingApp extends StatelessWidget {
  const GameAccountingApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Accounting Pro',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const Scaffold(body: Center(child: Text('Initializing...'))),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml lib/main.dart
git commit -m "chore: initial project scaffolding"
```

---

### Task 2: Database Schema (SQLite with Drift)

**Files:**
- Create: `lib/data/database.dart`

- [ ] **Step 1: Define tables and database class**

```dart
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
  RealColumn get price => real() Barry();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get note => text().nullable()();
}

@DriftDatabase(tables: [Publishers, Games, Entries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'game_accounting.db'));
    return NativeDatabase(file);
  });
}
```

- [ ] **Step 2: Generate code**

Run: `flutter pub run build_runner build`
Expected: `lib/data/database.g.dart` created.

- [ ] **Step 3: Commit**

```bash
git add lib/data/database.dart lib/data/database.g.dart
git commit -m "feat: define sqlite schema with drift"
```

---

### Task 3: Legacy CSV Migration Utility

**Files:**
- Create: `lib/data/migration_utility.dart`

- [ ] **Step 1: Implement CSV parser and importer**

```dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'database.dart';

class MigrationUtility {
  static Future<void> importFromCsv(File file, AppDatabase db) async {
    final input = file.openRead();
    final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList();
    
    // Skip header [用户, 日期, 厂商, 游戏, 项目, 单价, 数量, 总额, 备注]
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      final pubName = row[2].toString();
      final gameName = row[3].toString();
      
      // Upsert publisher
      final pub = await db.into(db.publishers).insertReturning(
        PublishersCompanion.insert(name: pubName),
        mode: InsertMode.insertOrIgnore,
      );
      
      // Upsert game (default category 'Service' for mobile style or 'Library' if logic applied)
      final game = await db.into(db.games).insertReturning(
        GamesCompanion.insert(
          publisherId: pub.id,
          name: gameName,
          category: 'Service', 
        ),
        mode: InsertMode.insertOrIgnore,
      );

      await db.into(db.entries).insert(EntriesCompanion.insert(
        gameId: game.id,
        date: DateTime.tryParse(row[1]) ?? DateTime.now(),
        itemName: row[4].toString(),
        price: double.tryParse(row[5].toString()) ?? 0.0,
        quantity: int.tryParse(row[6].toString()) ?? 1,
        note: Value(row[8].toString()),
      ));
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/data/migration_utility.dart
git commit -m "feat: add csv migration utility"
```

---

### Task 4: Smart Search-First Entry UI

**Files:**
- Create: `lib/ui/entry_screen.dart`

- [ ] **Step 1: Build autocomplete search field**

```dart
// Simplified Autocomplete logic
Autocomplete<Game>(
  displayStringForOption: (g) => g.name,
  optionsBuilder: (textEditingValue) async {
    if (textEditingValue.text == '') return const Iterable<Game>.empty();
    return await db.searchGames(textEditingValue.text);
  },
  onSelected: (selection) {
    // Auto-populate publisher and category
  },
)
```

- [ ] **Step 2: Implement "Add New" flow in modal**

- [ ] **Step 3: Commit**

```bash
git add lib/ui/entry_screen.dart
git commit -m "feat: implement smart search-first entry"
```

---

### Task 5: Dashboard with Separated Analytics

**Files:**
- Create: `lib/ui/dashboard_screen.dart`

- [ ] **Step 1: Implement "Library vs Service" toggle**

- [ ] **Step 2: Build charts using fl_chart**

- [ ] **Step 3: Commit**

```bash
git add lib/ui/dashboard_screen.dart
git commit -m "feat: add dashboard with library vs service views"
```
