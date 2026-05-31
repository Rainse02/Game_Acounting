import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/database.dart';
import 'ui/entry_screen.dart';
import 'ui/dashboard_screen.dart';

void main() {
  runApp(
    Provider<AppDatabase>(
      create: (context) => AppDatabase(),
      dispose: (context, db) => db.close(),
      child: const GameAccountingApp(),
    ),
  );
}

class GameAccountingApp extends StatelessWidget {
  const GameAccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '个人游戏账本 Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // Start with Dashboard

  @override
  void initState() {
    super.initState();
    // Seed initial data on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDatabase>().seedInitialData();
    });
  }

  static const List<Widget> _widgetOptions = <Widget>[
    Center(child: Text('明细列表 (即将推出)')),
    DashboardScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '明细',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: '看板',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const EntryScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
