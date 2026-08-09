# Changelog

## 1.1.1

### Fixed
- Editing a record's category no longer changes every historical record for
  the same game. Categories are now stored per ledger entry.
- Publisher names and publisher/game pairs are normalized and merged during
  the v3 database migration; case, repeated whitespace and invisible spacing
  no longer create pseudo-duplicate catalog records.
- CSV duplicate detection now includes the publisher/game pair and per-entry
  category.

### Added
- Entry detail view with exact record information, first/latest occurrence,
  covered days, monthly totals and a same-item timeline. Dashboard drill-down
  rows and history rows both open this view.

### Changed
- JSON backup format v2 preserves per-entry categories while remaining able to
  restore v1 backups.
- Database schema v3 migrates existing game categories onto entries and keeps
  catalog references stable while merging duplicates.
- Android release APKs now exclude unused locales and Cupertino icon assets,
  and compress native libraries for a smaller standalone download.

## 1.1.0

### Fixed
- **CSV round-trip corruption**: the v1 exporter and importer used different
  column layouts, so re-importing an exported file silently replaced every
  date with "today" and dropped all categories. Import is now header-driven
  and understands all three historical layouts (canonical, v1 in-app
  export, legacy Python export).
- **Cross-year chart merging**: the monthly trend chart grouped by month name
  only, adding e.g. January 2025 and January 2026 together. Statistics are
  now year-aware with a year selector (plus an all-years yearly view).
- Release builds no longer rely on duplicated Gradle `compileSdk` override
  hacks in the app module.

### Added
- Entry **editing** (tap any entry) and swipe-to-delete with **undo**.
- History tab: keyword search, category filter chips, date-range filter,
  month grouping with subtotals.
- **Import preview**: see exactly what will be imported, which rows were
  skipped and why, and which rows are duplicates (with a skip toggle) before
  anything is written. Imports run in a single transaction.
- **JSON full backup/restore** — lossless, includes publishers, games,
  entries and settings.
- **Monthly budget** with progress bar and overspend warning on the
  dashboard.
- English localization alongside Chinese (follows system language).
- CSV export: UTF-8 BOM (Excel-friendly), timestamped file names, desktop
  "save as" dialog on Windows.
- Unit tests for CSV parsing/round-trip, database CRUD, import dedup and
  backup restore; CI workflow runs analyze + tests on every push.
- Release workflow: tag `v*` → analyzed, tested, per-ABI APKs attached to a
  GitHub Release. Optional proper release signing via `key.properties` /
  repository secrets.

### Changed
- Database schema v2 (adds a key-value `settings` table; existing data is
  migrated automatically on first launch).
- App name is **GameA**.
  The application ID is **unchanged**, so v1.1.0 installs directly over v1.0
  without any data loss.
- Trimmed ProGuard keep-alls (`-keep class io.flutter.** { *; }`, unused
  Firebase/sqlcipher rules) that were defeating R8 shrinking.

### Removed
- `lib/ui/entry_screen.dart` (replaced by `entry_edit_screen.dart`).
- `lib/data/migration_utility.dart` (replaced by `csv_service.dart`).
- Committed `android/build/` artifacts and duplicate screenshots.
