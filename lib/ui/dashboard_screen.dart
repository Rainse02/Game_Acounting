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
    final Map<String, double> categoryTotals = {};
    for (var entry in entries) {
      final category = entry.game.category;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + (entry.entry.price * entry.entry.quantity);
    }

    final List<PieChartSectionData> sections = [];
    final colors = [Colors.deepPurple, Colors.orange, Colors.cyan, Colors.pink, Colors.green];
    int colorIndex = 0;

    categoryTotals.forEach((category, total) {
      sections.add(PieChartSectionData(
        color: colors[colorIndex % colors.length],
        value: total,
        title: category,
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
      colorIndex++;
    });

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildBarChart(List<EntryWithGame> entries) {
    // Group by month
    final Map<String, double> monthlyTotals = {};
    for (var entry in entries) {
      final month = DateFormat('MMM').format(entry.entry.date);
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + (entry.entry.price * entry.entry.quantity);
    }

    // Sort months? For simplicity let's just take the last 6 months or what we have.
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final presentMonths = months.where((m) => monthlyTotals.containsKey(m)).toList();

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: monthlyTotals.values.isEmpty ? 10 : monthlyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2,
          barTouchData: BarTouchData(enabled: true),
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
    );
  }
}
