import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../data/database.dart';
import '../data/migration_utility.dart';

class DataManagementScreen extends StatelessWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据管理'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('数据备份与导出'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.file_upload, color: Colors.blue),
              title: const Text('导出为 CSV'),
              subtitle: const Text('将所有账目导出为通用的表格文件'),
              onTap: () => _exportToCsv(context, database),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('数据恢复与导入'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.file_download, color: Colors.green),
              title: const Text('从 CSV 导入'),
              subtitle: const Text('选择旧的 CSV 账本文件合并到当前数据库'),
              onTap: () => _importFromCsv(context, database),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('危险操作'),
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('清空所有数据', style: TextStyle(color: Colors.red)),
              subtitle: const Text('此操作不可撤销，请谨慎操作'),
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
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  String _translateCategory(String category) {
    switch (category) {
      case 'Library': return '买断';
      case 'Service': return '内购';
      case 'Hardware': return '相关';
      default: return category;
    }
  }

  Future<void> _exportToCsv(BuildContext context, AppDatabase db) async {
    try {
      final query = db.select(db.entries).join([
        innerJoin(db.games, db.games.id.equalsExp(db.entries.gameId)),
      ]);

      final entries = await query.get();

      List<List<dynamic>> rows = [
        ['日期', '分类', '厂商', '游戏', '项目', '单价', '数量', '总额', '备注']
      ];

      for (var row in entries) {
        final entry = row.readTable(db.entries);
        final game = row.readTable(db.games);
        final pub = await db.getPublisherById(game.publisherId);
        
        rows.add([
          DateFormat('yyyy-MM-dd').format(entry.date),
          _translateCategory(game.category),
          pub?.name ?? 'Unknown',
          game.name,
          entry.itemName,
          entry.price,
          entry.quantity,
          entry.price * entry.quantity,
          entry.note ?? '',
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/game_ledger_export.csv');
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(file.path)], text: '游戏账本导出数据');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  Future<void> _importFromCsv(BuildContext context, AppDatabase db) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      try {
        await MigrationUtility.importFromCsv(file, db);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('导入成功')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败: $e')));
        }
      }
    }
  }

  void _showClearDialog(BuildContext context, AppDatabase db) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空？'),
        content: const Text('所有本地账目将被永久删除。建议在操作前先导出备份。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await db.delete(db.entries).go();
              await db.delete(db.games).go();
              await db.delete(db.publishers).go();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据已清空')));
              }
            },
            child: const Text('确定清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
