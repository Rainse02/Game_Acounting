import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/csv_service.dart';
import '../data/database.dart';
import 'common.dart';

/// Shows what a CSV import would do before any data is written, including
/// skipped rows and duplicate detection. Pops with the number of imported
/// entries when the user confirms.
class ImportPreviewScreen extends StatefulWidget {
  final CsvParseResult result;

  const ImportPreviewScreen({super.key, required this.result});

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  bool _skipDuplicates = true;
  bool _importing = false;

  int get _duplicateCount =>
      widget.result.entries.where((e) => e.isDuplicate).length;

  int get _importCount => _skipDuplicates
      ? widget.result.entries.length - _duplicateCount
      : widget.result.entries.length;

  Future<void> _confirmImport() async {
    if (_importing) return;
    setState(() => _importing = true);

    final db = context.read<AppDatabase>();
    try {
      final inserted = await CsvService.importEntries(
        db,
        widget.result.entries,
        skipDuplicates: _skipDuplicates,
      );
      if (mounted) Navigator.of(context).pop(inserted);
    } catch (e) {
      if (mounted) {
        setState(() => _importing = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.importFailed('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = widget.result;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importPreviewTitle),
      ),
      body: Column(
        children: [
          // Summary header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.format == CsvFormat.legacyPython
                      ? l10n.detectedFormatLegacy
                      : l10n.detectedFormatHeadered,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text(l10n.readyRows('${result.entries.length}')),
                  ],
                ),
                if (_duplicateCount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.copy_all,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 6),
                      Text(l10n.duplicateRows('$_duplicateCount')),
                    ],
                  ),
                ],
                if (result.issues.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 6),
                      Text(l10n.issueRows('${result.issues.length}')),
                    ],
                  ),
                ],
                if (_duplicateCount > 0)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.skipDuplicates),
                    value: _skipDuplicates,
                    onChanged: (value) =>
                        setState(() => _skipDuplicates = value),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Row list
          Expanded(
            child: ListView.builder(
              itemCount:
                  result.entries.length + (result.issues.isEmpty ? 0 : 1),
              itemBuilder: (context, index) {
                if (index < result.entries.length) {
                  final e = result.entries[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: categoryColor(e.category),
                      child: Icon(categoryIcon(e.category),
                          size: 16, color: Colors.white),
                    ),
                    title: Text(e.item),
                    subtitle: Text(
                        '${e.game} · ${dateFormat.format(e.date)}'
                        '${e.publisher.isNotEmpty ? ' · ${e.publisher}' : ''}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(money(e.total),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        if (e.isDuplicate)
                          Text(
                            l10n.duplicateTag,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.orange),
                          ),
                      ],
                    ),
                  );
                }

                // Issues section at the end of the list
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.issuesTitle,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                      const SizedBox(height: 8),
                      for (final issue in result.issues)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${l10n.rowLabel('${issue.rowNumber}')}: '
                            '${issue.message}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Confirm bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _importCount > 0 && !_importing ? _confirmImport : null,
                  icon: _importing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_done),
                  label: Text(
                      '${l10n.importAction} (${l10n.entriesCount('$_importCount')})'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
