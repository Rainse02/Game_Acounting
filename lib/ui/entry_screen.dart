import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../data/database.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _gameController = TextEditingController();
  final _publisherController = TextEditingController();
  final _categoryController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _noteController = TextEditingController();

  Game? _selectedGame;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _gameController.dispose();
    _publisherController.dispose();
    _categoryController.dispose();
    _itemNameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final db = context.read<AppDatabase>();
    
    int gameId;
    if (_selectedGame != null && _selectedGame!.name == _gameController.text) {
      gameId = _selectedGame!.id;
    } else {
      final publisherName = _publisherController.text.trim();
      final publishers = await db.getAllPublishers();
      int? pubId;
      try {
        pubId = publishers.firstWhere((p) => p.name.toLowerCase() == publisherName.toLowerCase()).id;
      } catch (_) {
        pubId = await db.addPublisher(PublishersCompanion.insert(name: publisherName));
      }

      gameId = await db.addGame(GamesCompanion.insert(
        publisherId: pubId,
        name: _gameController.text.trim(),
        category: _categoryController.text.trim(),
      ));
    }

    await db.addEntry(EntriesCompanion.insert(
      gameId: gameId,
      date: _selectedDate,
      itemName: _itemNameController.text.trim(),
      price: double.parse(_priceController.text),
      quantity: drift.Value(int.parse(_quantityController.text)),
      note: drift.Value(_noteController.text.isEmpty ? null : _noteController.text),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('记一笔'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Autocomplete<Game>(
                displayStringForOption: (Game option) => option.name,
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Game>.empty();
                  }
                  return await db.searchGames(textEditingValue.text);
                },
                onSelected: (Game selection) async {
                  setState(() {
                    _selectedGame = selection;
                    _gameController.text = selection.name;
                    _categoryController.text = selection.category;
                  });
                  final pub = await db.getPublisherById(selection.publisherId);
                  if (pub != null) {
                    setState(() {
                      _publisherController.text = pub.name;
                    });
                  }
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  if (controller.text != _gameController.text && _gameController.text.isNotEmpty && controller.text.isEmpty) {
                    controller.text = _gameController.text;
                  }

                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: '游戏名称',
                      hintText: '搜索或输入新游戏',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      _gameController.text = value;
                      _selectedGame = null;
                    },
                    validator: (value) => (value == null || value.isEmpty) ? '请输入游戏名称' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _publisherController,
                decoration: const InputDecoration(labelText: '厂商'),
                validator: (value) => (value == null || value.isEmpty) ? '请输入厂商' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoryController.text.isEmpty ? null : _categoryController.text,
                decoration: const InputDecoration(labelText: '类型'),
                items: [
                  {'val': 'Library', 'label': '单机/买断'},
                  {'val': 'Service', 'label': '网游/内购'},
                  {'val': 'Hardware', 'label': '游戏相关'},
                ].map((item) {
                  return DropdownMenuItem<String>(
                    value: item['val'] as String,
                    child: Text(item['label'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoryController.text = value ?? '';
                  });
                },
                validator: (value) => (value == null || value.isEmpty) ? '请选择类型' : null,
              ),
              const Divider(height: 32),
              TextFormField(
                controller: _itemNameController,
                decoration: const InputDecoration(labelText: '项目名称', hintText: '例如：月卡、皮肤、大作本体'),
                validator: (value) => (value == null || value.isEmpty) ? '请输入项目名称' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: '单价', prefixText: '¥'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return '输入金额';
                        if (double.tryParse(value) == null) return '格式错误';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: '数量'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return '输入数量';
                        if (int.tryParse(value) == null) return '格式错误';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: '日期',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: '备注 (选填)'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('保存记录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
