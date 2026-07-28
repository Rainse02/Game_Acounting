import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import 'common.dart';
import 'entry_edit_screen.dart';

class EntryListScreen extends StatefulWidget {
  const EntryListScreen({super.key});

  @override
  State<EntryListScreen> createState() => _EntryListScreenState();
}

class _EntryListScreenState extends State<EntryListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedCategories = <String>{};
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategories.isNotEmpty ||
      _dateRange != null;

  List<EntryDetail> _applyFilters(List<EntryDetail> all) {
    return all.where((d) {
      if (_selectedCategories.isNotEmpty &&
          !_selectedCategories.contains(d.game.category)) {
        return false;
      }
      if (_dateRange != null) {
        final date = DateTime(
            d.entry.date.year, d.entry.date.month, d.entry.date.day);
        if (date.isBefore(_dateRange!.start) ||
            date.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final haystack = '${d.game.name} ${d.entry.itemName} '
                '${d.publisher.name} ${d.entry.note ?? ''}'
            .toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategories.clear();
      _dateRange = null;
    });
  }

  Future<void> _deleteWithUndo(EntryDetail detail) async {
    final db = context.read<AppDatabase>();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    await db.deleteEntry(detail.entry);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.entryDeleted),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => db.restoreEntry(detail.entry),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.entriesTitle),
        actions: [
          IconButton(
            icon: Icon(
              Icons.date_range,
              color: _dateRange != null
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: l10n.dateRange,
            onPressed: _pickDateRange,
          ),
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: l10n.clearFilters,
              onPressed: _clearFilters,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.trim()),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: Categories.all.map((key) {
                    final selected = _selectedCategories.contains(key);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(categoryLabel(context, key)),
                        selected: selected,
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedCategories.add(key);
                            } else {
                              _selectedCategories.remove(key);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<EntryDetail>>(
        stream: database.watchAllEntryDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data ?? [];
          if (all.isEmpty) {
            return Center(child: Text(l10n.emptyEntries));
          }

          final filtered = _applyFilters(all);
          if (filtered.isEmpty) {
            return Center(child: Text(l10n.noMatch));
          }

          return _buildGroupedList(filtered);
        },
      ),
    );
  }

  /// Builds the list grouped by month, with a subtotal per month.
  Widget _buildGroupedList(List<EntryDetail> details) {
    // details are already sorted newest first by the query.
    final items = <_ListItem>[];
    String? currentMonth;
    for (final d in details) {
      final monthKey = DateFormat('yyyy-MM').format(d.entry.date);
      if (monthKey != currentMonth) {
        currentMonth = monthKey;
        final monthDetails = details.where((x) =>
            DateFormat('yyyy-MM').format(x.entry.date) == monthKey);
        final subtotal =
            monthDetails.fold(0.0, (sum, x) => sum + x.total);
        items.add(_ListItem.header(
            monthKey, subtotal, monthDetails.length));
      }
      items.add(_ListItem.entry(d));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isHeader) {
          return _buildMonthHeader(item);
        }
        return _buildEntryTile(item.detail!);
      },
    );
  }

  Widget _buildMonthHeader(_ListItem item) {
    final l10n = context.l10n;
    final parts = item.monthKey!.split('-');
    final label = DateFormat.yMMMM(
            Localizations.localeOf(context).toString())
        .format(DateTime(int.parse(parts[0]), int.parse(parts[1])));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            '${l10n.entriesCount('${item.count}')} · ${money(item.subtotal)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(EntryDetail detail) {
    final entry = detail.entry;
    final game = detail.game;

    return Dismissible(
      key: ValueKey('entry-${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteWithUndo(detail),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: categoryColor(game.category),
            child: Icon(categoryIcon(game.category), color: Colors.white),
          ),
          title: Text(entry.itemName),
          subtitle: Text(
              '${game.name} · ${DateFormat('yyyy-MM-dd').format(entry.date)}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(detail.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.redAccent,
                ),
              ),
              if (entry.quantity > 1)
                Text('x${entry.quantity}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EntryEditScreen(existing: detail),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ListItem {
  final bool isHeader;
  final EntryDetail? detail;
  final String? monthKey;
  final double subtotal;
  final int count;

  _ListItem.header(this.monthKey, this.subtotal, this.count)
      : isHeader = true,
        detail = null;

  _ListItem.entry(this.detail)
      : isHeader = false,
        monthKey = null,
        subtotal = 0,
        count = 0;
}
