# How to apply this upgrade to your repository

This folder is an **overlay** for the existing
[Rainse02/Game_Acounting](https://github.com/Rainse02/Game_Acounting) repo:
copy its contents over your checkout, delete a few superseded files, run the
bootstrap script, and commit.

## 1. Copy the overlay

From the repo root:

```bash
# unzip game_ledger_v2_upgrade.zip somewhere, then:
cp -r /path/to/game_ledger_v2_upgrade/* /path/to/game_ledger_v2_upgrade/.gitignore .
cp -r /path/to/game_ledger_v2_upgrade/.github .
```

(On Windows just drag-merge the folders in Explorer, replacing when asked —
and copy `.gitignore` and `.github/` too, they are hidden.)

## 2. Delete superseded files

```bash
git rm lib/ui/entry_screen.dart          # replaced by lib/ui/entry_edit_screen.dart
git rm lib/data/migration_utility.dart   # replaced by lib/data/csv_service.dart
git rm lib/data/database.g.dart          # stale; regenerated in step 3
git rm test/widget_test.dart             # replaced by real unit tests
git rm -r android/build                  # committed build artifact
# duplicate screenshots (same images, hash-named copies)
git rm screenshots/282f75b6b8aabec34a595b51f2840d1f.jpg \
       screenshots/dae7df36ded6eb98917e8664f9dbd4e7.jpg \
       screenshots/dbf40f0935fb235032be5fcbc12c752f.jpg
```

Files you should **keep** as-is (the overlay does not touch them):
`android/settings.gradle.kts`, `android/build.gradle.kts`,
`android/build_extras.gradle`, `android/gradle.properties`, the `windows/`
runner, launcher icons, `LICENSE`, `legacy/app.py`.

## 3. Regenerate code and verify

```bash
./tool/bootstrap.sh      # Windows: tool\bootstrap.bat
flutter analyze
flutter test
flutter run              # try it out
```

`bootstrap` runs `flutter pub get`, regenerates `lib/data/database.g.dart`
(the schema gained a `settings` table → schema v2) and generates the
localization classes. **The project will not compile before this step** —
both generated files are intentionally not shipped in the overlay.

Then commit the regenerated `lib/data/database.g.dart` together with
everything else:

```bash
git add -A
git commit -m "v2.0.0: editable history, reliable import/export, budgets, l10n, smaller APKs"
```

## 4. Existing users' data

- The application ID is unchanged → v2 installs **directly over v1**.
- On first launch drift migrates the database from schema v1 to v2
  automatically (adds the `settings` table; existing tables are untouched).
- Old CSV files (both the v1 in-app export and the legacy Python export)
  import correctly through the new header-driven importer.

## 5. Release build (small APKs)

```bash
flutter build apk --release --split-per-abi
```

Ship `app-arm64-v8a-release.apk` to virtually all modern phones
(`armeabi-v7a` covers very old devices). Do **not** ship
`app-release.apk` (the fat universal APK) — it bundles every CPU
architecture and is roughly 3× larger.

Or simply push a tag (`git tag v2.0.0 && git push --tags`) and let the
bundled GitHub Actions release workflow build, test and publish the APKs
for you.

For real release signing, copy `android/key.properties.example` to
`android/key.properties` and fill in your keystore (see README).
