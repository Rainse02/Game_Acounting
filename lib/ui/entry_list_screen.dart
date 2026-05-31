import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../data/database.dart';

class EntryListScreen extends StatelessWidget {
  const EntryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('消费明细'),
      ),
      body: StreamBuilder<List<EntryWithGame>>(
        stream: database.watchAllEntriesWithGame(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const Center(child: Text('暂无明细记录'));
          }

          // Group by date
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final item = entries[index];
              final entry = item.entry;
              final game = item.game;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getCategoryColor(game.category),
                    child: Icon(_getCategoryIcon(game.category), color: Colors.white),
                  ),
                  title: Text(entry.itemName),
                  subtitle: Text('${game.name} · ${DateFormat('yyyy-MM-dd').format(entry.date)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${(entry.price * entry.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
                      ),
                      if (entry.quantity > 1)
                        Text('x${entry.quantity}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  onLongPress: () => _showDeleteDialog(context, database, entry),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Library': return Colors.deepPurple;
      case 'Service': return Colors.orange;
      case 'Hardware': return Colors.cyan;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Library': return Icons.collections_bookmark;
      case 'Service': return Icons.subscriptions;
      case 'Hardware': return Icons.settings_input_component;
      default: return Icons.help_outline;
    }
  }

  void _showDeleteDialog(BuildContext context, AppDatabase db, Entry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这笔消费记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await db.deleteEntry(entry);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
