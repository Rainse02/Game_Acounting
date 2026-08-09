import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import 'common.dart';
import 'entry_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedCategory = 'All';
  int? _selectedYear; // null = all years

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
      ),
      body: StreamBuilder<List<EntryDetail>>(
        stream: database.watchAllEntryDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          final allEntries = snapshot.data ?? [];
          if (allEntries.isEmpty) {
            return Center(child: Text(l10n.emptyDashboard));
          }

          final List<int> years = allEntries
              .map((e) => e.entry.date.year)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));
          if (_selectedYear != null && !years.contains(_selectedYear)) {
            _selectedYear = null;
          }

          var filtered = _selectedCategory == 'All'
              ? allEntries
              : allEntries
                  .where((e) => e.category == _selectedCategory)
                  .toList();
          if (_selectedYear != null) {
            filtered = filtered
                .where((e) => e.entry.date.year == _selectedYear)
                .toList();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildCategorySelector(context)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildYearSelector(years),
                const SizedBox(height: 16),
                _buildBudgetCard(database, allEntries),
                const SizedBox(height: 16),
                _buildSummaryCards(filtered),
                const SizedBox(height: 32),
                Text(
                  l10n.spendingByCategory,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildPieChart(filtered),
                const SizedBox(height: 32),
                Text(
                  _selectedYear == null ? l10n.yearlyTrend : l10n.monthlyTrend,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildTrendChart(filtered),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  Widget _buildCategorySelector(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(
              value: 'All',
              label: Text(l10n.filterAll),
              icon: const Icon(Icons.all_inclusive)),
          for (final key in Categories.all)
            ButtonSegment(
                value: key,
                label: Text(categoryLabel(context, key)),
                icon: Icon(categoryIcon(key))),
        ],
        selected: {_selectedCategory},
        onSelectionChanged: (Set<String> newSelection) {
          setState(() => _selectedCategory = newSelection.first);
        },
      ),
    );
  }

  Widget _buildYearSelector(List<int> years) {
    final l10n = context.l10n;
    return Row(
      children: [
        const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        DropdownButton<int?>(
          value: _selectedYear,
          underline: const SizedBox.shrink(),
          items: [
            DropdownMenuItem<int?>(value: null, child: Text(l10n.yearAll)),
            for (final year in years)
              DropdownMenuItem<int?>(value: year, child: Text('$year')),
          ],
          onChanged: (value) => setState(() => _selectedYear = value),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Budget
  // ---------------------------------------------------------------------------

  Widget _buildBudgetCard(AppDatabase db, List<EntryDetail> allEntries) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final monthSpent = allEntries
        .where((e) =>
            e.entry.date.year == now.year && e.entry.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.total);

    return StreamBuilder<String?>(
      stream: db.watchSetting(SettingKeys.monthlyBudget),
      builder: (context, snapshot) {
        final budget = double.tryParse(snapshot.data ?? '');

        Widget subtitle;
        Widget? progress;
        if (budget == null || budget <= 0) {
          subtitle = Text(l10n.noBudgetHint,
              style: const TextStyle(fontSize: 12, color: Colors.grey));
        } else {
          final remaining = budget - monthSpent;
          final over = remaining < 0;
          subtitle = Text(
            over
                ? l10n.overBudget(money(-remaining))
                : l10n.budgetRemaining(money(remaining)),
            style: TextStyle(
              fontSize: 12,
              color: over ? Colors.red : Colors.grey,
              fontWeight: over ? FontWeight.bold : FontWeight.normal,
            ),
          );
          progress = Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (monthSpent / budget).clamp(0.0, 1.0),
                minHeight: 8,
                color: over
                    ? Colors.red
                    : (monthSpent / budget > 0.8
                        ? Colors.orange
                        : Colors.green),
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showBudgetDialog(db, budget),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.thisMonthSpending,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                      if (budget != null && budget > 0)
                        Text(
                          '${l10n.monthlyBudget}: ${money(budget)}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    money(monthSpent),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  subtitle,
                  if (progress != null) progress,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBudgetDialog(AppDatabase db, double? current) async {
    final l10n = context.l10n;
    final controller = TextEditingController(
        text: current == null || current <= 0
            ? ''
            : current.toStringAsFixed(
                current.truncateToDouble() == current ? 0 : 2));

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.setBudget),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.budgetInputHint,
            prefixText: '¥',
          ),
        ),
        actions: [
          if (current != null && current > 0)
            TextButton(
              onPressed: () async {
                await db.removeSetting(SettingKeys.monthlyBudget);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l10n.clearBudget,
                  style: const TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final value = double.tryParse(controller.text.trim());
              if (value != null && value > 0) {
                await db.setSetting(
                    SettingKeys.monthlyBudget, value.toString());
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Summary
  // ---------------------------------------------------------------------------

  Widget _buildSummaryCards(List<EntryDetail> entries) {
    final l10n = context.l10n;
    final totalSpending = entries.fold(0.0, (sum, e) => sum + e.total);
    final entryCount = entries.length;
    final avgPerEntry = entryCount > 0 ? totalSpending / entryCount : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            l10n.totalSpending,
            money(totalSpending),
            Icons.account_balance_wallet,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            l10n.avgPerEntry,
            money(avgPerEntry),
            Icons.analytics,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pie chart
  // ---------------------------------------------------------------------------

  Widget _buildPieChart(List<EntryDetail> entries) {
    final l10n = context.l10n;
    final Map<String, double> categoryTotals = {
      for (final key in Categories.all) key: 0.0,
    };

    for (final entry in entries) {
      final category = entry.category;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + entry.total;
    }

    final sections = <PieChartSectionData>[];
    final sectionKeys = <String>[];

    categoryTotals.forEach((category, total) {
      if (total > 0) {
        sections.add(PieChartSectionData(
          color: categoryColor(category),
          value: total,
          title: categoryLabel(context, category),
          radius: 60,
          titleStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ));
        sectionKeys.add(category);
      }
    });

    if (sections.isEmpty) {
      return Center(child: Text(l10n.noCategoryData));
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (event is FlTapUpEvent &&
                      pieTouchResponse != null &&
                      pieTouchResponse.touchedSection != null) {
                    final index =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                    if (index >= 0 && index < sectionKeys.length) {
                      final categoryKey = sectionKeys[index];
                      _showDrillDown(
                        context,
                        categoryLabel(context, categoryKey),
                        entries
                            .where((e) => e.category == categoryKey)
                            .toList(),
                      );
                    }
                  }
                },
              ),
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(l10n.chartTapHintPie,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Trend chart (monthly within a year, or yearly for "all years")
  // ---------------------------------------------------------------------------

  Widget _buildTrendChart(List<EntryDetail> entries) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    // Bucket key -> (label, total, entries)
    final totals = <String, double>{};
    final buckets = <String, List<EntryDetail>>{};
    final labels = <String, String>{};

    if (_selectedYear == null) {
      for (final e in entries) {
        final key = e.entry.date.year.toString().padLeft(4, '0');
        totals[key] = (totals[key] ?? 0) + e.total;
        buckets.putIfAbsent(key, () => []).add(e);
        labels[key] = e.entry.date.year.toString();
      }
    } else {
      for (final e in entries) {
        final key = e.entry.date.month.toString().padLeft(2, '0');
        totals[key] = (totals[key] ?? 0) + e.total;
        buckets.putIfAbsent(key, () => []).add(e);
        labels[key] = DateFormat.MMM(locale)
            .format(DateTime(_selectedYear!, e.entry.date.month));
      }
    }

    final keys = totals.keys.toList()..sort();
    if (keys.isEmpty) {
      return Center(child: Text(l10n.noCategoryData));
    }

    final maxTotal = totals.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxTotal * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  if (event is FlTapUpEvent &&
                      barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    final index = barTouchResponse.spot!.touchedBarGroupIndex;
                    if (index >= 0 && index < keys.length) {
                      final key = keys[index];
                      _showDrillDown(context, labels[key]!, buckets[key]!);
                    }
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${labels[keys[group.x.toInt()]]}\n',
                      const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: money(rod.toY),
                          style: const TextStyle(color: Colors.yellowAccent),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < keys.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(labels[keys[index]]!,
                              style: const TextStyle(fontSize: 10)),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(keys.length, (index) {
                final key = keys[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: totals[key]!,
                      color: Theme.of(context).colorScheme.primary,
                      width: 16,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(l10n.chartTapHintBar,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Drill-down bottom sheet
  // ---------------------------------------------------------------------------

  void _showDrillDown(
      BuildContext context, String title, List<EntryDetail> filteredEntries) {
    final gameGroups = <int, List<EntryDetail>>{};
    for (final e in filteredEntries) {
      gameGroups.putIfAbsent(e.game.id, () => []).add(e);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: gameGroups.length,
                  itemBuilder: (context, index) {
                    final gameId = gameGroups.keys.elementAt(index);
                    final groupEntries = gameGroups[gameId]!;
                    final representative = groupEntries.first;
                    final gameTotal =
                        groupEntries.fold(0.0, (sum, e) => sum + e.total);

                    return ExpansionTile(
                      title: Text(representative.game.name),
                      subtitle: Text(representative.publisher.name),
                      trailing: Text(money(gameTotal),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      children: groupEntries
                          .map((e) => ListTile(
                                title: Text(e.entry.itemName),
                                subtitle: Text(DateFormat('yyyy-MM-dd')
                                    .format(e.entry.date)),
                                trailing: Text(money(e.total)),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EntryDetailScreen(
                                      entryId: e.entry.id,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
