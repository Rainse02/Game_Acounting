import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import 'common.dart';

/// Creates a new entry, or edits [existing] when provided.
class EntryEditScreen extends StatefulWidget {
  final EntryDetail? existing;

  const EntryEditScreen({super.key, this.existing});

  @override
  State<EntryEditScreen> createState() => _EntryEditScreenState();
}

class _EntryEditScreenState extends State<EntryEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _gameController = TextEditingController();
  final _publisherController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();

  String? _category;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      final entry = existing.entry;
      _gameController.text = existing.game.name;
      _publisherController.text = existing.publisher.name;
      _category = entry.category;
      _itemNameController.text = entry.itemName;
      _priceController.text = entry.price.toStringAsFixed(
          entry.price.truncateToDouble() == entry.price ? 0 : 2);
      _quantityController.text = entry.quantity.toString();
      _selectedDate = entry.date;
      _noteController.text = entry.note ?? '';
    }
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  @override
  void dispose() {
    _gameController.dispose();
    _publisherController.dispose();
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

  Future<int> _resolveGameId(AppDatabase db) async {
    final gameName = _gameController.text.trim();
    final publisher =
        await db.getOrCreatePublisher(_publisherController.text.trim());
    final game =
        await db.getOrCreateGame(publisher.id, gameName, _category ?? '');
    return game.id;
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final db = context.read<AppDatabase>();
    final l10n = context.l10n;
    await db.transaction(() async {
      final gameId = await _resolveGameId(db);
      final companion = EntriesCompanion(
        gameId: drift.Value(gameId),
        category: drift.Value(_category!),
        date: drift.Value(_selectedDate),
        itemName: drift.Value(_itemNameController.text.trim()),
        price: drift.Value(double.parse(_priceController.text)),
        quantity: drift.Value(int.parse(_quantityController.text)),
        note: drift.Value(
            _noteController.text.isEmpty ? null : _noteController.text),
      );

      if (_isEditing) {
        await db.updateEntry(widget.existing!.entry.id, companion);
      } else {
        await db.addEntry(companion);
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.saved)));
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteEntry() async {
    final db = context.read<AppDatabase>();
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await db.deleteEntry(widget.existing!.entry);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editEntryTitle : l10n.newEntryTitle),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.delete,
              onPressed: _deleteEntry,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Autocomplete<GameSuggestion>(
                initialValue: TextEditingValue(text: _gameController.text),
                displayStringForOption: (option) => option.game.name,
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<GameSuggestion>.empty();
                  }
                  return db.searchGameSuggestions(textEditingValue.text);
                },
                optionsViewBuilder: (context, onSelected, options) {
                  final items = options.toList();
                  final screenWidth = MediaQuery.sizeOf(context).width;
                  final optionsWidth =
                      screenWidth > 552 ? 520.0 : screenWidth - 32;
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        width: optionsWidth,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 280),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final option = items[index];
                              return ListTile(
                                dense: true,
                                title: Text(option.game.name),
                                subtitle: Text(option.publisher.name),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
                onSelected: (GameSuggestion selection) {
                  setState(() {
                    _gameController.text = selection.game.name;
                    _publisherController.text = selection.publisher.name;
                    _category = selection.game.category;
                  });
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: l10n.gameName,
                      hintText: l10n.gameSearchHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      _gameController.text = value;
                    },
                    validator: (value) => (value == null || value.isEmpty)
                        ? l10n.fieldRequired
                        : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _publisherController,
                decoration: InputDecoration(labelText: l10n.publisher),
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.fieldRequired
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(labelText: l10n.category),
                items: Categories.all.map((key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(categoryLabel(context, key)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _category = value);
                },
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.fieldRequired
                    : null,
              ),
              const Divider(height: 32),
              TextFormField(
                controller: _itemNameController,
                decoration: InputDecoration(
                  labelText: l10n.itemName,
                  hintText: l10n.itemHint,
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.fieldRequired
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                          labelText: l10n.unitPrice, prefixText: '¥'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.fieldRequired;
                        }
                        if (double.tryParse(value) == null) {
                          return l10n.invalidNumber;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(labelText: l10n.quantity),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.fieldRequired;
                        }
                        final parsed = int.tryParse(value);
                        if (parsed == null || parsed < 1) {
                          return l10n.invalidNumber;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: l10n.date,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(labelText: l10n.noteOptional),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
