# Game Ledger v2.0.0 Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Merge the upgraded Game Ledger v2 project from `docs/game_ledger_v2_upgrade` into the repository root, run code generation/bootstrapping, verify tests and static analysis, and commit the changes.

**Architecture:** Copy the v2 overlay files into the root directory, delete obsolete/superseded files (v1 entry screen, migration utility, stale generated code, duplicate screenshots), execute build code generation (Drift schema v2 & Flutter l10n), run unit tests and static analysis to ensure full correctness, and commit.

**Tech Stack:** Flutter, Dart 3.x, Drift DB, Provider, fl_chart, flutter_localizations, GFM / GitHub Actions.

## Global Constraints

- Preserve git history where applicable; execute explicit file removals for superseded files.
- Application ID (`com.example.game_accounting_pro`) remains unchanged for seamless over-the-top update without data loss.
- Schema migration from v1 to v2 must be preserved in `database.dart`.
- All tests (`flutter test`) and static analysis (`flutter analyze`) must pass without errors.

---

### Task 1: Overlay v2 upgrade files and remove superseded files

**Files:**
- Copy Overlay: All files under `docs/game_ledger_v2_upgrade/` to repository root (`.`).
- Delete:
  - `lib/ui/entry_screen.dart`
  - `lib/data/migration_utility.dart`
  - `lib/data/database.g.dart`
  - `test/widget_test.dart`
  - `screenshots/282f75b6b8aabec34a595b51f2840d1f.jpg`
  - `screenshots/dae7df36ded6eb98917e8664f9dbd4e7.jpg`
  - `screenshots/dbf40f0935fb235032be5fcbc12c752f.jpg`

- [ ] **Step 1: Copy overlay files to project root**

Run powershell command to copy overlay files from `docs/game_ledger_v2_upgrade` into root.

- [ ] **Step 2: Remove superseded files via git rm**

Run `git rm` on obsolete files.

- [ ] **Step 3: Verify workspace file structure**

Check that new files (`csv_service.dart`, `backup_service.dart`, `entry_edit_screen.dart`, `import_preview_screen.dart`, `l10n/`, etc.) exist in `lib/`.

---

### Task 2: Bootstrapping and Code Generation

**Files:**
- Generates: `lib/data/database.g.dart`
- Generates: `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_zh.dart`

- [ ] **Step 1: Run pub get**

Run `flutter pub get`.

- [ ] **Step 2: Run build_runner for Drift database code generation**

Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 3: Generate Flutter localizations**

Run `flutter gen-l10n`.

---

### Task 3: Static Analysis and Automated Testing

**Files:**
- Verify: Entire codebase (`lib/`, `test/`)

- [ ] **Step 1: Run static analysis**

Run `flutter analyze`.
Expected: "No issues found!"

- [ ] **Step 2: Run unit test suite**

Run `flutter test`.
Expected: All tests pass (csv_service_test, database_test).

---

### Task 4: Git Commit

- [ ] **Step 1: Stage and commit all changes**

Run `git add -A` and `git commit -m "v2.0.0: editable history, reliable import/export, budgets, l10n, smaller APKs"`.
