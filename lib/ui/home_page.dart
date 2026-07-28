import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import 'common.dart';
import 'dashboard_screen.dart';
import 'data_management_screen.dart';
import 'entry_edit_screen.dart';
import 'entry_list_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDatabase>().seedInitialData();
    });
  }

  static const List<Widget> _screens = <Widget>[
    DashboardScreen(),
    EntryListScreen(),
    DataManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: l10n.navDashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: l10n.navEntries,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.storage),
            label: l10n.navData,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
      floatingActionButton: _selectedIndex != 2 // Hide FAB on the data tab
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const EntryEditScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
