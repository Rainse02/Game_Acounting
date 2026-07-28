@echo off
REM One-time setup after cloning (or after pulling schema changes).
cd /d "%~dp0.."

call flutter pub get || exit /b 1
call dart run build_runner build --delete-conflicting-outputs || exit /b 1
call flutter gen-l10n || exit /b 1

echo.
echo Done. Verify with: flutter analyze ^&^& flutter test
