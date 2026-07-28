#!/usr/bin/env bash
# One-time setup after cloning (or after pulling schema changes).
set -euo pipefail
cd "$(dirname "$0")/.."

flutter pub get

# Regenerate the drift database code (lib/data/database.g.dart).
dart run build_runner build --delete-conflicting-outputs

# Generate localizations (lib/l10n/app_localizations*.dart).
flutter gen-l10n

echo
echo "Done. Verify with: flutter analyze && flutter test"
