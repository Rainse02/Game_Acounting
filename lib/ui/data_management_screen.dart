import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/backup_service.dart';
import '../data/csv_service.dart';
import '../data/database.dart';
import 'common.dart';
import 'import_preview_screen.dart';

class DataManagementScreen extends StatelessWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dataTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(l10n.sectionBackup),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.table_chart, color: Colors.blue),
                  title: Text(l10n.exportCsvTitle),
                  subtitle: Text(l10n.exportCsvSubtitle),
                  onTap: () => _exportCsv(context, database),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.backup_outlined, color: Colors.indigo),
                  title: Text(l10n.exportJsonTitle),
                  subtitle: Text(l10n.exportJsonSubtitle),
                  onTap: () => _exportJson(context, database),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.sectionRestore),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.file_download, color: Colors.green),
                  title: Text(l10n.importCsvTitle),
                  subtitle: Text(l10n.importCsvSubtitle),
                  onTap: () => _importCsv(context, database),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_backup_restore,
                      color: Colors.teal),
                  title: Text(l10n.restoreJsonTitle),
                  subtitle: Text(l10n.restoreJsonSubtitle),
                  onTap: () => _restoreJson(context, database),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.sectionDanger),
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text(l10n.clearAllTitle,
                  style: const TextStyle(color: Colors.red)),
              subtitle: Text(l10n.clearAllSubtitle),
              onTap: () => _showClearDialog(context, database),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Export helpers
  // ---------------------------------------------------------------------------

  static String _timestamp() =>
      DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

  /// Saves the file locally (to user-selected path or public Download directory),
  /// and shows a SnackBar with local path and optional "Share" action.
  static Future<void> _deliverFile(
      BuildContext context, String content, String fileName) async {
    final l10n = context.l10n;
    String? savedPath;

    try {
      savedPath = await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: utf8.encode(content),
      );
    } catch (_) {
      // Fallback if FilePicker saveFile is unsupported on specific platform version
    }

    if (savedPath == null) {
      Directory? targetDir;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          targetDir = downloadDir;
        }
      }
      targetDir ??= await getDownloadsDirectory();
      targetDir ??= await getApplicationDocumentsDirectory();

      final file = File('${targetDir.path}/$fileName');
      await file.writeAsString(content, encoding: utf8);
      savedPath = file.path;
    }

    if (!context.mounted) return;

    final finalPath = savedPath;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.exportSavedTo(finalPath)),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
        action: SnackBarAction(
          label: '分享',
          onPressed: () {
            messenger.hideCurrentSnackBar();
            // ignore: deprecated_member_use
            Share.shareXFiles([XFile(finalPath)]);
          },
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, AppDatabase db) async {
    final l10n = context.l10n;
    try {
      final details = await db.getAllEntryDetails();
      final csvData = CsvService.exportCsv(details);
      if (context.mounted) {
        await _deliverFile(
            context, csvData, 'game_ledger_${_timestamp()}.csv');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.exportFailed('$e'))));
      }
    }
  }

  Future<void> _exportJson(BuildContext context, AppDatabase db) async {
    final l10n = context.l10n;
    try {
      final jsonData = await BackupService.exportJson(db);
      if (context.mounted) {
        await _deliverFile(
            context, jsonData, 'game_ledger_backup_${_timestamp()}.json');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.exportFailed('$e'))));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Import helpers
  // ---------------------------------------------------------------------------

  static Future<String?> _pickTextFile(List<String> extensions) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    if (result == null) return null;

    final file = result.files.single;
    if (file.bytes != null) {
      return utf8.decode(file.bytes!, allowMalformed: true);
    }
    if (file.path != null) {
      return File(file.path!).readAsString();
    }
    return null;
  }

  Future<void> _importCsv(BuildContext context, AppDatabase db) async {
    final l10n = context.l10n;
    try {
      final content = await _pickTextFile(['csv']);
      if (content == null) return;

      final parsed = CsvService.parse(content);
      final existing = await db.getAllEntryDetails();
      CsvService.markDuplicates(parsed.entries, existing);

      if (!context.mounted) return;
      final imported = await Navigator.of(context).push<int>(
        MaterialPageRoute(
          builder: (context) => ImportPreviewScreen(result: parsed),
        ),
      );

      if (imported != null && imported > 0 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.importedMessage('$imported'))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.importFailed('$e'))));
      }
    }
  }

  Future<void> _restoreJson(BuildContext context, AppDatabase db) async {
    final l10n = context.l10n;
    try {
      final content = await _pickTextFile(['json']);
      if (content == null) return;

      final data = BackupService.parse(content);

      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.restoreConfirmTitle),
          content: Text(l10n.restoreConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.restoreJsonTitle,
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      final restored = await BackupService.restore(db, data);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.restoreDone('$restored'))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.importFailed('$e'))));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Danger zone
  // ---------------------------------------------------------------------------

  void _showClearDialog(BuildContext context, AppDatabase db) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmClearTitle),
        content: Text(l10n.confirmClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              await db.clearAllData();
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(l10n.clearedMessage)));
              }
            },
            child: Text(l10n.confirmClearAction,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
