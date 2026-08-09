import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import 'common.dart';
import 'entry_edit_screen.dart';

/// Shows one ledger entry and time-based statistics for the same game item.
class EntryDetailScreen extends StatelessWidget {
  final int entryId;

  const EntryDetailScreen({super.key, required this.entryId});

  @override
  Widget build(BuildContext context) {
    final database = context.read<AppDatabase>();
    final l10n = context.l10n;

    return StreamBuilder<List<EntryDetail>>(
      stream: database.watchAllEntryDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.entryDetailsTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final all = snapshot.data ?? const <EntryDetail>[];
        EntryDetail? selected;
        for (final detail in all) {
          if (detail.entry.id == entryId) {
            selected = detail;
            break;
          }
        }

        if (selected == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.entryDetailsTitle)),
            body: Center(child: Text(l10n.entryNotFound)),
          );
        }

        final current = selected;
        final itemKey = catalogNameKey(current.entry.itemName);
        final related = all
            .where((detail) =>
                detail.game.id == current.game.id &&
                catalogNameKey(detail.entry.itemName) == itemKey)
            .toList()
          ..sort((a, b) {
            final byDate = b.entry.date.compareTo(a.entry.date);
            return byDate != 0 ? byDate : b.entry.id.compareTo(a.entry.id);
          });

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.entryDetailsTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.edit,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EntryEditScreen(existing: current),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _EntryInformationCard(detail: current),
              const SizedBox(height: 12),
              _ItemTimelineCard(selectedId: entryId, entries: related),
            ],
          ),
        );
      },
    );
  }
}

class _EntryInformationCard extends StatelessWidget {
  final EntryDetail detail;

  const _EntryInformationCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entry = detail.entry;
    final color = categoryColor(detail.category);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recordInformation,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  child:
                      Icon(categoryIcon(detail.category), color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.itemName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text('${detail.game.name} · ${detail.publisher.name}'),
                    ],
                  ),
                ),
                Text(
                  money(detail.total),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 28),
            _InformationRow(
              icon: Icons.event_outlined,
              label: l10n.date,
              value: DateFormat('yyyy-MM-dd').format(entry.date),
            ),
            _InformationRow(
              icon: Icons.sell_outlined,
              label: l10n.category,
              value: categoryLabel(context, detail.category),
            ),
            _InformationRow(
              icon: Icons.calculate_outlined,
              label: l10n.unitPrice,
              value: '${money(entry.price)} × ${entry.quantity}',
            ),
            if (entry.note?.isNotEmpty == true)
              _InformationRow(
                icon: Icons.notes_outlined,
                label: l10n.note,
                value: entry.note!,
              ),
          ],
        ),
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 76,
            child: Text(label,
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ItemTimelineCard extends StatelessWidget {
  final int selectedId;
  final List<EntryDetail> entries;

  const _ItemTimelineCard({
    required this.selectedId,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final total = entries.fold(0.0, (sum, detail) => sum + detail.total);
    final average = entries.isEmpty ? 0.0 : total / entries.length;
    final newest = entries.first.entry.date;
    final oldest = entries.last.entry.date;
    final daysCovered = newest.difference(oldest).inDays.abs() + 1;

    final monthly = <String, List<EntryDetail>>{};
    for (final detail in entries) {
      final key = DateFormat('yyyy-MM').format(detail.entry.date);
      monthly.putIfAbsent(key, () => []).add(detail);
    }
    final monthKeys = monthly.keys.toList()..sort((a, b) => b.compareTo(a));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.itemTimeline,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricBox(
                  label: l10n.entriesCount('${entries.length}'),
                  value: money(total),
                ),
                _MetricBox(
                  label: l10n.avgPerEntry,
                  value: money(average),
                ),
                _MetricBox(
                  label: l10n.firstRecord,
                  value: DateFormat('yyyy-MM-dd').format(oldest),
                ),
                _MetricBox(
                  label: l10n.lastRecord,
                  value: DateFormat('yyyy-MM-dd').format(newest),
                ),
                _MetricBox(
                  label: l10n.timeSpan,
                  value: l10n.daysCount('$daysCovered'),
                ),
              ],
            ),
            const Divider(height: 28),
            Text(
              l10n.monthlyBreakdown,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            for (final key in monthKeys)
              _MonthlyRow(
                label: DateFormat.yMMMM(locale).format(
                  DateTime.parse('$key-01'),
                ),
                count: monthly[key]!.length,
                total: monthly[key]!
                    .fold(0.0, (sum, detail) => sum + detail.total),
              ),
            const Divider(height: 28),
            Text(
              l10n.recordTimeline,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            for (final detail in entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  detail.entry.id == selectedId
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: detail.entry.id == selectedId
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor,
                ),
                title: Text(DateFormat('yyyy-MM-dd').format(detail.entry.date)),
                subtitle: detail.entry.note?.isNotEmpty == true
                    ? Text(detail.entry.note!)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (detail.entry.id == selectedId) ...[
                      Text(
                        l10n.selectedEntry,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(money(detail.total)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MonthlyRow extends StatelessWidget {
  final String label;
  final int count;
  final double total;

  const _MonthlyRow({
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            context.l10n.entriesCount('$count'),
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
          const SizedBox(width: 12),
          Text(money(total),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
