import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/database.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('消费看板'),
      ),
      body: StreamBuilder<List<EntryWithGame>>(
        stream: database.watchAllEntriesWithGame(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('错误: ${snapshot.error}'));
          }

          final allEntries = snapshot.data ?? [];
          if (allEntries.isEmpty) {
            return const Center(child: Text('暂无记录，快去记一笔吧！'));
          }

          final filteredEntries = _selectedCategory == 'All'
              ? allEntries
              : allEntries.where((e) => e.game.category == _selectedCategory).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategorySelector(),
                const SizedBox(height: 24),
                _buildSummaryCards(filteredEntries),
                const SizedBox(height: 32),
                const Text(
                  '消费分布',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildPieChart(filteredEntries),
                const SizedBox(height: 32),
                const Text(
                  '每月趋势',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildBarChart(filteredEntries),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Center(
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'All', label: Text('全部'), icon: Icon(Icons.all_inclusive)),
          ButtonSegment(value: 'Library', label: Text('买断'), icon: Icon(Icons.collections_bookmark)),
          ButtonSegment(value: 'Service', label: Text('内购'), icon: Icon(Icons.subscriptions)),
          ButtonSegment(value: 'Hardware', label: Text('相关'), icon: Icon(Icons.settings_input_component)),
        ],
        selected: {_selectedCategory},
        onSelectionChanged: (Set<String> newSelection) {
          setState(() {
            _selectedCategory = newSelection.first;
          });
        },
      ),
    );
  }

  Widget _buildSummaryCards(List<EntryWithGame> entries) {
    final totalSpending = entries.fold(0.0, (sum, e) => sum + (e.entry.price * e.entry.quantity));
    final entryCount = entries.length;
    final avgPerEntry = entryCount > 0 ? totalSpending / entryCount : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            '总支出',
            '¥${totalSpending.toStringAsFixed(2)}',
            Icons.account_balance_wallet,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            '平均每笔',
            '¥${avgPerEntry.toStringAsFixed(2)}',
            Icons.analytics,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
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

  Widget _buildPieChart(List<EntryWithGame> entries) {
    final Map<String, double> categoryTotals = {
      'Library': 0.0,
      'Service': 0.0,
      'Hardware': 0.0,
    };
    
    for (var entry in entries) {
      final category = entry.game.category;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + (entry.entry.price * entry.entry.quantity);
    }

    final List<PieChartSectionData> sections = [];
    final labels = {'Library': '买断', 'Service': '内购', 'Hardware': '相关'};
    final colors = {'Library': Colors.deepPurple, 'Service': Colors.orange, 'Hardware': Colors.cyan};

    categoryTotals.forEach((category, total) {
      if (total > 0) {
        sections.add(PieChartSectionData(
          color: colors[category] ?? Colors.grey,
          value: total,
          title: labels[category],
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ));
      }
    });

    if (sections.isEmpty) return const Center(child: Text('暂无分类数据'));

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Catch any interaction that results in a touched section
                  if (event is FlTapUpEvent && pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                    final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    if (index >= 0 && index < sections.length) {
                      final categoryLabel = sections[index].title;
                      debugPrint('PIE_CLICK: $categoryLabel');
                      
                      try {
                        final categoryKey = labels.keys.firstWhere((k) => labels[k] == categoryLabel);
                        _showCategoryDrillDown(context, categoryLabel, entries.where((e) => e.game.category == categoryKey).toList());
                      } catch (e) {
                        debugPrint('PIE_ERROR: $e');
                      }
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
        const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text('提示：点击圆环查看分类明细', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      ],
    );
  }

  void _showCategoryDrillDown(BuildContext context, String title, List<EntryWithGame> filteredEntries) {
    final Map<String, List<EntryWithGame>> gameGroups = {};
    for (var e in filteredEntries) {
      gameGroups.putIfAbsent(e.game.name, () => []).add(e);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                child: Text('$title 消费明细', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: gameGroups.length,
                  itemBuilder: (context, index) {
                    final gameName = gameGroups.keys.elementAt(index);
                    final entries = gameGroups[gameName]!;
                    final gameTotal = entries.fold(0.0, (sum, e) => sum + (e.entry.price * e.entry.quantity));

                    return ExpansionTile(
                      title: Text(gameName),
                      trailing: Text('¥${gameTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      children: entries.map((e) => ListTile(
                        title: Text(e.entry.itemName),
                        subtitle: Text(DateFormat('yyyy-MM-dd').format(e.entry.date)),
                        trailing: Text('¥${(e.entry.price * e.entry.quantity).toStringAsFixed(2)}'),
                      )).toList(),
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

  Widget _buildBarChart(List<EntryWithGame> entries) {
    final Map<String, double> monthlyTotals = {};
    final Map<String, List<EntryWithGame>> monthlyEntries = {};

    for (var entry in entries) {
      final month = DateFormat('MMM').format(entry.entry.date);
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + (entry.entry.price * entry.entry.quantity);
      monthlyEntries.putIfAbsent(month, () => []).add(entry);
    }

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final presentMonths = months.where((m) => monthlyTotals.containsKey(m)).toList();

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: monthlyTotals.values.isEmpty ? 10 : monthlyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  if (event is FlTapUpEvent && barTouchResponse != null && barTouchResponse.spot != null) {
                    final index = barTouchResponse.spot!.touchedBarGroupIndex;
                    if (index >= 0 && index < presentMonths.length) {
                      final monthName = presentMonths[index];
                      debugPrint('BAR_CLICK: $monthName');
                      _showCategoryDrillDown(context, monthName, monthlyEntries[monthName]!);
                    }
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${presentMonths[group.x.toInt()]}\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: '¥${rod.toY.toStringAsFixed(2)}',
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
                      if (value.toInt() >= 0 && value.toInt() < presentMonths.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(presentMonths[value.toInt()], style: const TextStyle(fontSize: 10)),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(presentMonths.length, (index) {
                final month = presentMonths[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: monthlyTotals[month]!,
                      color: Theme.of(context).colorScheme.primary,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text('提示：点击柱状图查看月度明细', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      ],
    );
  }
}
