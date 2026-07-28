// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PublishersTable extends Publishers
    with TableInfo<$PublishersTable, Publisher> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PublishersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _iconPathMeta =
      const VerificationMeta('iconPath');
  @override
  late final GeneratedColumn<String> iconPath = GeneratedColumn<String>(
      'icon_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name, iconPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'publishers';
  @override
  VerificationContext validateIntegrity(Insertable<Publisher> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_path')) {
      context.handle(_iconPathMeta,
          iconPath.isAcceptableOrUnknown(data['icon_path']!, _iconPathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Publisher map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Publisher(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      iconPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_path']),
    );
  }

  @override
  $PublishersTable createAlias(String alias) {
    return $PublishersTable(attachedDatabase, alias);
  }
}

class Publisher extends DataClass implements Insertable<Publisher> {
  final int id;
  final String name;
  final String? iconPath;
  const Publisher({required this.id, required this.name, this.iconPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || iconPath != null) {
      map['icon_path'] = Variable<String>(iconPath);
    }
    return map;
  }

  PublishersCompanion toCompanion(bool nullToAbsent) {
    return PublishersCompanion(
      id: Value(id),
      name: Value(name),
      iconPath: iconPath == null && nullToAbsent
          ? const Value.absent()
          : Value(iconPath),
    );
  }

  factory Publisher.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Publisher(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconPath: serializer.fromJson<String?>(json['iconPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'iconPath': serializer.toJson<String?>(iconPath),
    };
  }

  Publisher copyWith(
          {int? id,
          String? name,
          Value<String?> iconPath = const Value.absent()}) =>
      Publisher(
        id: id ?? this.id,
        name: name ?? this.name,
        iconPath: iconPath.present ? iconPath.value : this.iconPath,
      );
  Publisher copyWithCompanion(PublishersCompanion data) {
    return Publisher(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconPath: data.iconPath.present ? data.iconPath.value : this.iconPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Publisher(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconPath: $iconPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, iconPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Publisher &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconPath == this.iconPath);
}

class PublishersCompanion extends UpdateCompanion<Publisher> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> iconPath;
  const PublishersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconPath = const Value.absent(),
  });
  PublishersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.iconPath = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Publisher> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? iconPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconPath != null) 'icon_path': iconPath,
    });
  }

  PublishersCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<String?>? iconPath}) {
    return PublishersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconPath.present) {
      map['icon_path'] = Variable<String>(iconPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PublishersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconPath: $iconPath')
          ..write(')'))
        .toString();
  }
}

class $GamesTable extends Games with TableInfo<$GamesTable, Game> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _publisherIdMeta =
      const VerificationMeta('publisherId');
  @override
  late final GeneratedColumn<int> publisherId = GeneratedColumn<int>(
      'publisher_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES publishers (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconPathMeta =
      const VerificationMeta('iconPath');
  @override
  late final GeneratedColumn<String> iconPath = GeneratedColumn<String>(
      'icon_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, publisherId, name, category, iconPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'games';
  @override
  VerificationContext validateIntegrity(Insertable<Game> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('publisher_id')) {
      context.handle(
          _publisherIdMeta,
          publisherId.isAcceptableOrUnknown(
              data['publisher_id']!, _publisherIdMeta));
    } else if (isInserting) {
      context.missing(_publisherIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('icon_path')) {
      context.handle(_iconPathMeta,
          iconPath.isAcceptableOrUnknown(data['icon_path']!, _iconPathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Game map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Game(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      publisherId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}publisher_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      iconPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_path']),
    );
  }

  @override
  $GamesTable createAlias(String alias) {
    return $GamesTable(attachedDatabase, alias);
  }
}

class Game extends DataClass implements Insertable<Game> {
  final int id;
  final int publisherId;
  final String name;
  final String category;
  final String? iconPath;
  const Game(
      {required this.id,
      required this.publisherId,
      required this.name,
      required this.category,
      this.iconPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['publisher_id'] = Variable<int>(publisherId);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || iconPath != null) {
      map['icon_path'] = Variable<String>(iconPath);
    }
    return map;
  }

  GamesCompanion toCompanion(bool nullToAbsent) {
    return GamesCompanion(
      id: Value(id),
      publisherId: Value(publisherId),
      name: Value(name),
      category: Value(category),
      iconPath: iconPath == null && nullToAbsent
          ? const Value.absent()
          : Value(iconPath),
    );
  }

  factory Game.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Game(
      id: serializer.fromJson<int>(json['id']),
      publisherId: serializer.fromJson<int>(json['publisherId']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      iconPath: serializer.fromJson<String?>(json['iconPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'publisherId': serializer.toJson<int>(publisherId),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'iconPath': serializer.toJson<String?>(iconPath),
    };
  }

  Game copyWith(
          {int? id,
          int? publisherId,
          String? name,
          String? category,
          Value<String?> iconPath = const Value.absent()}) =>
      Game(
        id: id ?? this.id,
        publisherId: publisherId ?? this.publisherId,
        name: name ?? this.name,
        category: category ?? this.category,
        iconPath: iconPath.present ? iconPath.value : this.iconPath,
      );
  Game copyWithCompanion(GamesCompanion data) {
    return Game(
      id: data.id.present ? data.id.value : this.id,
      publisherId:
          data.publisherId.present ? data.publisherId.value : this.publisherId,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      iconPath: data.iconPath.present ? data.iconPath.value : this.iconPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Game(')
          ..write('id: $id, ')
          ..write('publisherId: $publisherId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('iconPath: $iconPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, publisherId, name, category, iconPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Game &&
          other.id == this.id &&
          other.publisherId == this.publisherId &&
          other.name == this.name &&
          other.category == this.category &&
          other.iconPath == this.iconPath);
}

class GamesCompanion extends UpdateCompanion<Game> {
  final Value<int> id;
  final Value<int> publisherId;
  final Value<String> name;
  final Value<String> category;
  final Value<String?> iconPath;
  const GamesCompanion({
    this.id = const Value.absent(),
    this.publisherId = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.iconPath = const Value.absent(),
  });
  GamesCompanion.insert({
    this.id = const Value.absent(),
    required int publisherId,
    required String name,
    required String category,
    this.iconPath = const Value.absent(),
  })  : publisherId = Value(publisherId),
        name = Value(name),
        category = Value(category);
  static Insertable<Game> custom({
    Expression<int>? id,
    Expression<int>? publisherId,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? iconPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (publisherId != null) 'publisher_id': publisherId,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (iconPath != null) 'icon_path': iconPath,
    });
  }

  GamesCompanion copyWith(
      {Value<int>? id,
      Value<int>? publisherId,
      Value<String>? name,
      Value<String>? category,
      Value<String?>? iconPath}) {
    return GamesCompanion(
      id: id ?? this.id,
      publisherId: publisherId ?? this.publisherId,
      name: name ?? this.name,
      category: category ?? this.category,
      iconPath: iconPath ?? this.iconPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (publisherId.present) {
      map['publisher_id'] = Variable<int>(publisherId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (iconPath.present) {
      map['icon_path'] = Variable<String>(iconPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamesCompanion(')
          ..write('id: $id, ')
          ..write('publisherId: $publisherId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('iconPath: $iconPath')
          ..write(')'))
        .toString();
  }
}

class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
      'game_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES games (id)'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _itemNameMeta =
      const VerificationMeta('itemName');
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
      'item_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, gameId, date, itemName, price, quantity, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(Insertable<Entry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(_gameIdMeta,
          gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta));
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('item_name')) {
      context.handle(_itemNameMeta,
          itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta));
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      gameId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}game_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      itemName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_name'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }
}

class Entry extends DataClass implements Insertable<Entry> {
  final int id;
  final int gameId;
  final DateTime date;
  final String itemName;
  final double price;
  final int quantity;
  final String? note;
  const Entry(
      {required this.id,
      required this.gameId,
      required this.date,
      required this.itemName,
      required this.price,
      required this.quantity,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<int>(gameId);
    map['date'] = Variable<DateTime>(date);
    map['item_name'] = Variable<String>(itemName);
    map['price'] = Variable<double>(price);
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      gameId: Value(gameId),
      date: Value(date),
      itemName: Value(itemName),
      price: Value(price),
      quantity: Value(quantity),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Entry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int>(json['gameId']),
      date: serializer.fromJson<DateTime>(json['date']),
      itemName: serializer.fromJson<String>(json['itemName']),
      price: serializer.fromJson<double>(json['price']),
      quantity: serializer.fromJson<int>(json['quantity']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int>(gameId),
      'date': serializer.toJson<DateTime>(date),
      'itemName': serializer.toJson<String>(itemName),
      'price': serializer.toJson<double>(price),
      'quantity': serializer.toJson<int>(quantity),
      'note': serializer.toJson<String?>(note),
    };
  }

  Entry copyWith(
          {int? id,
          int? gameId,
          DateTime? date,
          String? itemName,
          double? price,
          int? quantity,
          Value<String?> note = const Value.absent()}) =>
      Entry(
        id: id ?? this.id,
        gameId: gameId ?? this.gameId,
        date: date ?? this.date,
        itemName: itemName ?? this.itemName,
        price: price ?? this.price,
        quantity: quantity ?? this.quantity,
        note: note.present ? note.value : this.note,
      );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      date: data.date.present ? data.date.value : this.date,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      price: data.price.present ? data.price.value : this.price,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('date: $date, ')
          ..write('itemName: $itemName, ')
          ..write('price: $price, ')
          ..write('quantity: $quantity, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, gameId, date, itemName, price, quantity, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.date == this.date &&
          other.itemName == this.itemName &&
          other.price == this.price &&
          other.quantity == this.quantity &&
          other.note == this.note);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<int> id;
  final Value<int> gameId;
  final Value<DateTime> date;
  final Value<String> itemName;
  final Value<double> price;
  final Value<int> quantity;
  final Value<String?> note;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.date = const Value.absent(),
    this.itemName = const Value.absent(),
    this.price = const Value.absent(),
    this.quantity = const Value.absent(),
    this.note = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.id = const Value.absent(),
    required int gameId,
    required DateTime date,
    required String itemName,
    required double price,
    this.quantity = const Value.absent(),
    this.note = const Value.absent(),
  })  : gameId = Value(gameId),
        date = Value(date),
        itemName = Value(itemName),
        price = Value(price);
  static Insertable<Entry> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<DateTime>? date,
    Expression<String>? itemName,
    Expression<double>? price,
    Expression<int>? quantity,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (date != null) 'date': date,
      if (itemName != null) 'item_name': itemName,
      if (price != null) 'price': price,
      if (quantity != null) 'quantity': quantity,
      if (note != null) 'note': note,
    });
  }

  EntriesCompanion copyWith(
      {Value<int>? id,
      Value<int>? gameId,
      Value<DateTime>? date,
      Value<String>? itemName,
      Value<double>? price,
      Value<int>? quantity,
      Value<String?>? note}) {
    return EntriesCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      date: date ?? this.date,
      itemName: itemName ?? this.itemName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('date: $date, ')
          ..write('itemName: $itemName, ')
          ..write('price: $price, ')
          ..write('quantity: $quantity, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) => Setting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PublishersTable publishers = $PublishersTable(this);
  late final $GamesTable games = $GamesTable(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [publishers, games, entries, settings];
}

typedef $$PublishersTableCreateCompanionBuilder = PublishersCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> iconPath,
});
typedef $$PublishersTableUpdateCompanionBuilder = PublishersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> iconPath,
});

final class $$PublishersTableReferences
    extends BaseReferences<_$AppDatabase, $PublishersTable, Publisher> {
  $$PublishersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GamesTable, List<Game>> _gamesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.games,
          aliasName:
              $_aliasNameGenerator(db.publishers.id, db.games.publisherId));

  $$GamesTableProcessedTableManager get gamesRefs {
    final manager = $$GamesTableTableManager($_db, $_db.games)
        .filter((f) => f.publisherId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gamesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PublishersTableFilterComposer
    extends Composer<_$AppDatabase, $PublishersTable> {
  $$PublishersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconPath => $composableBuilder(
      column: $table.iconPath, builder: (column) => ColumnFilters(column));

  Expression<bool> gamesRefs(
      Expression<bool> Function($$GamesTableFilterComposer f) f) {
    final $$GamesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.games,
        getReferencedColumn: (t) => t.publisherId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GamesTableFilterComposer(
              $db: $db,
              $table: $db.games,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PublishersTableOrderingComposer
    extends Composer<_$AppDatabase, $PublishersTable> {
  $$PublishersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconPath => $composableBuilder(
      column: $table.iconPath, builder: (column) => ColumnOrderings(column));
}

class $$PublishersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PublishersTable> {
  $$PublishersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconPath =>
      $composableBuilder(column: $table.iconPath, builder: (column) => column);

  Expression<T> gamesRefs<T extends Object>(
      Expression<T> Function($$GamesTableAnnotationComposer a) f) {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.games,
        getReferencedColumn: (t) => t.publisherId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GamesTableAnnotationComposer(
              $db: $db,
              $table: $db.games,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PublishersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PublishersTable,
    Publisher,
    $$PublishersTableFilterComposer,
    $$PublishersTableOrderingComposer,
    $$PublishersTableAnnotationComposer,
    $$PublishersTableCreateCompanionBuilder,
    $$PublishersTableUpdateCompanionBuilder,
    (Publisher, $$PublishersTableReferences),
    Publisher,
    PrefetchHooks Function({bool gamesRefs})> {
  $$PublishersTableTableManager(_$AppDatabase db, $PublishersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PublishersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PublishersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PublishersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> iconPath = const Value.absent(),
          }) =>
              PublishersCompanion(
            id: id,
            name: name,
            iconPath: iconPath,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> iconPath = const Value.absent(),
          }) =>
              PublishersCompanion.insert(
            id: id,
            name: name,
            iconPath: iconPath,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PublishersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({gamesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (gamesRefs) db.games],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (gamesRefs)
                    await $_getPrefetchedData<Publisher, $PublishersTable,
                            Game>(
                        currentTable: table,
                        referencedTable:
                            $$PublishersTableReferences._gamesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PublishersTableReferences(db, table, p0)
                                .gamesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.publisherId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PublishersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PublishersTable,
    Publisher,
    $$PublishersTableFilterComposer,
    $$PublishersTableOrderingComposer,
    $$PublishersTableAnnotationComposer,
    $$PublishersTableCreateCompanionBuilder,
    $$PublishersTableUpdateCompanionBuilder,
    (Publisher, $$PublishersTableReferences),
    Publisher,
    PrefetchHooks Function({bool gamesRefs})>;
typedef $$GamesTableCreateCompanionBuilder = GamesCompanion Function({
  Value<int> id,
  required int publisherId,
  required String name,
  required String category,
  Value<String?> iconPath,
});
typedef $$GamesTableUpdateCompanionBuilder = GamesCompanion Function({
  Value<int> id,
  Value<int> publisherId,
  Value<String> name,
  Value<String> category,
  Value<String?> iconPath,
});

final class $$GamesTableReferences
    extends BaseReferences<_$AppDatabase, $GamesTable, Game> {
  $$GamesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PublishersTable _publisherIdTable(_$AppDatabase db) =>
      db.publishers.createAlias(
          $_aliasNameGenerator(db.games.publisherId, db.publishers.id));

  $$PublishersTableProcessedTableManager get publisherId {
    final $_column = $_itemColumn<int>('publisher_id')!;

    final manager = $$PublishersTableTableManager($_db, $_db.publishers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_publisherIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$EntriesTable, List<Entry>> _entriesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.entries,
          aliasName: $_aliasNameGenerator(db.games.id, db.entries.gameId));

  $$EntriesTableProcessedTableManager get entriesRefs {
    final manager = $$EntriesTableTableManager($_db, $_db.entries)
        .filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$GamesTableFilterComposer extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconPath => $composableBuilder(
      column: $table.iconPath, builder: (column) => ColumnFilters(column));

  $$PublishersTableFilterComposer get publisherId {
    final $$PublishersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.publisherId,
        referencedTable: $db.publishers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PublishersTableFilterComposer(
              $db: $db,
              $table: $db.publishers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> entriesRefs(
      Expression<bool> Function($$EntriesTableFilterComposer f) f) {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.entries,
        getReferencedColumn: (t) => t.gameId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EntriesTableFilterComposer(
              $db: $db,
              $table: $db.entries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GamesTableOrderingComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconPath => $composableBuilder(
      column: $table.iconPath, builder: (column) => ColumnOrderings(column));

  $$PublishersTableOrderingComposer get publisherId {
    final $$PublishersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.publisherId,
        referencedTable: $db.publishers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PublishersTableOrderingComposer(
              $db: $db,
              $table: $db.publishers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get iconPath =>
      $composableBuilder(column: $table.iconPath, builder: (column) => column);

  $$PublishersTableAnnotationComposer get publisherId {
    final $$PublishersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.publisherId,
        referencedTable: $db.publishers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PublishersTableAnnotationComposer(
              $db: $db,
              $table: $db.publishers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> entriesRefs<T extends Object>(
      Expression<T> Function($$EntriesTableAnnotationComposer a) f) {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.entries,
        getReferencedColumn: (t) => t.gameId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.entries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GamesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GamesTable,
    Game,
    $$GamesTableFilterComposer,
    $$GamesTableOrderingComposer,
    $$GamesTableAnnotationComposer,
    $$GamesTableCreateCompanionBuilder,
    $$GamesTableUpdateCompanionBuilder,
    (Game, $$GamesTableReferences),
    Game,
    PrefetchHooks Function({bool publisherId, bool entriesRefs})> {
  $$GamesTableTableManager(_$AppDatabase db, $GamesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> publisherId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String?> iconPath = const Value.absent(),
          }) =>
              GamesCompanion(
            id: id,
            publisherId: publisherId,
            name: name,
            category: category,
            iconPath: iconPath,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int publisherId,
            required String name,
            required String category,
            Value<String?> iconPath = const Value.absent(),
          }) =>
              GamesCompanion.insert(
            id: id,
            publisherId: publisherId,
            name: name,
            category: category,
            iconPath: iconPath,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GamesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({publisherId = false, entriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (entriesRefs) db.entries],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (publisherId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.publisherId,
                    referencedTable:
                        $$GamesTableReferences._publisherIdTable(db),
                    referencedColumn:
                        $$GamesTableReferences._publisherIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (entriesRefs)
                    await $_getPrefetchedData<Game, $GamesTable, Entry>(
                        currentTable: table,
                        referencedTable:
                            $$GamesTableReferences._entriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$GamesTableReferences(db, table, p0).entriesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.gameId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$GamesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GamesTable,
    Game,
    $$GamesTableFilterComposer,
    $$GamesTableOrderingComposer,
    $$GamesTableAnnotationComposer,
    $$GamesTableCreateCompanionBuilder,
    $$GamesTableUpdateCompanionBuilder,
    (Game, $$GamesTableReferences),
    Game,
    PrefetchHooks Function({bool publisherId, bool entriesRefs})>;
typedef $$EntriesTableCreateCompanionBuilder = EntriesCompanion Function({
  Value<int> id,
  required int gameId,
  required DateTime date,
  required String itemName,
  required double price,
  Value<int> quantity,
  Value<String?> note,
});
typedef $$EntriesTableUpdateCompanionBuilder = EntriesCompanion Function({
  Value<int> id,
  Value<int> gameId,
  Value<DateTime> date,
  Value<String> itemName,
  Value<double> price,
  Value<int> quantity,
  Value<String?> note,
});

final class $$EntriesTableReferences
    extends BaseReferences<_$AppDatabase, $EntriesTable, Entry> {
  $$EntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GamesTable _gameIdTable(_$AppDatabase db) => db.games
      .createAlias($_aliasNameGenerator(db.entries.gameId, db.games.id));

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager($_db, $_db.games)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemName => $composableBuilder(
      column: $table.itemName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.gameId,
        referencedTable: $db.games,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GamesTableFilterComposer(
              $db: $db,
              $table: $db.games,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemName => $composableBuilder(
      column: $table.itemName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.gameId,
        referencedTable: $db.games,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GamesTableOrderingComposer(
              $db: $db,
              $table: $db.games,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.gameId,
        referencedTable: $db.games,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GamesTableAnnotationComposer(
              $db: $db,
              $table: $db.games,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EntriesTable,
    Entry,
    $$EntriesTableFilterComposer,
    $$EntriesTableOrderingComposer,
    $$EntriesTableAnnotationComposer,
    $$EntriesTableCreateCompanionBuilder,
    $$EntriesTableUpdateCompanionBuilder,
    (Entry, $$EntriesTableReferences),
    Entry,
    PrefetchHooks Function({bool gameId})> {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> gameId = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> itemName = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<String?> note = const Value.absent(),
          }) =>
              EntriesCompanion(
            id: id,
            gameId: gameId,
            date: date,
            itemName: itemName,
            price: price,
            quantity: quantity,
            note: note,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int gameId,
            required DateTime date,
            required String itemName,
            required double price,
            Value<int> quantity = const Value.absent(),
            Value<String?> note = const Value.absent(),
          }) =>
              EntriesCompanion.insert(
            id: id,
            gameId: gameId,
            date: date,
            itemName: itemName,
            price: price,
            quantity: quantity,
            note: note,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$EntriesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({gameId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (gameId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.gameId,
                    referencedTable: $$EntriesTableReferences._gameIdTable(db),
                    referencedColumn:
                        $$EntriesTableReferences._gameIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$EntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EntriesTable,
    Entry,
    $$EntriesTableFilterComposer,
    $$EntriesTableOrderingComposer,
    $$EntriesTableAnnotationComposer,
    $$EntriesTableCreateCompanionBuilder,
    $$EntriesTableUpdateCompanionBuilder,
    (Entry, $$EntriesTableReferences),
    Entry,
    PrefetchHooks Function({bool gameId})>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PublishersTableTableManager get publishers =>
      $$PublishersTableTableManager(_db, _db.publishers);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db, _db.games);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
