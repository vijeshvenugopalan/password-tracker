import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class TrackerDatabase {
  Logger log = getLogger('TrackerDatabase');

  final initScripts = [
    '''
    create table tInfo(
      key   text primary key,
      value text)
    ''',
    '''
    create table tItem(
      id        integer primary key,
      name      text,
      is_folder integer,
      parent    integer
    )
    ''',
    '''
    create table tItemData(
      id       integer primary key,
      username text,
      url      text,
      password text,
      secret   text,
      comments text,
      item_id  integer,
      foreign key (item_id)
          references tItem (id)
    )
    ''',
    '''
    insert into tItem (name,is_folder,parent) values ('/',1,1)
    ''',
    '''
    insert into tItem (name,is_folder,parent) values ('test-folder',1,1)
    ''',
    '''
    insert into tItem (name,is_folder,parent) values ('test-item',0,2)
    ''',
    '''
    insert into tItemData (username,url,item_id) values ('user','google.com',3)
    ''',
  ];
  final migrationScripts = [];

  TrackerDatabase._privateConstructor();
  static final TrackerDatabase instance = TrackerDatabase._privateConstructor();
  Future<Database> database;
  Future<Database> open() async {
    database = openDatabase(
      join(await getDatabasesPath(), 'tracker.db'),
      onCreate: (db, version) async {
        for (final script in initScripts) {
          await db.execute(script);
        }
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        for (var i = oldVersion - 1; i <= newVersion - 1; i++) {
          await db.execute(migrationScripts[i]);
        }
      },
      version: migrationScripts.length + 1,
    );
    return database;
  }

  Future<void> insert(String key, String value) async {
    log.i('65 : key=$key :: value=$value');
    Database db = await open();
    var map = {
      'key': key,
      'value': value,
    };
    await db.insert(
      'tInfo',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.close();
  }

  Future<String> getValue(String key) async {
    log.i('80 : inside getvalue');

    String value;
    Database db = await open();
    final List<Map<String, dynamic>> maps = await db.query('tInfo');
    await db.close();
    for (var i = 0; i < maps.length; i++) {
      if (maps[i]['key'] == key) {
        value = maps[i]['value'];
      }
    }
    log.i('91 : value=$value');
    return value;
  }

  Future<int> insertItem(Item item) async {
    Database db = await open();
    int id = item.id;
    if (id > 0) {
      await db.update(
        'tItem',
        item.toMap(),
        where: "id = ?",
        whereArgs: [id],
      );
    } else {
      id = await db.insert(
        'tItem',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return id;
  }

  Future<int> insertItemData(ItemData itemData) async {
    Database db = await open();
    int id = itemData.id;
    if (id > 0) {
      await db.update(
        'tItemData',
        itemData.toMap(),
        where: "id = ?",
        whereArgs: [id],
      );
    } else {
      id = await db.insert(
        'tItemData',
        itemData.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return id;
  }

  Future<void> deleteItem(Item item) async {
    Database db = await open();
    int id = item.id;
    if (id > 0) {
      await db.delete(
        'tItem',
        where: "id = ?",
        whereArgs: [id],
      );
    }
  }

  Future<void> deleteItemData(ItemData itemData) async {
    Database db = await open();
    int id = itemData.id;
    if (id > 0) {
      await db.delete(
        'tItemData',
        where: "id = ?",
        whereArgs: [id],
      );
    }
    return id;
  }

  Future<List<Item>> getAllItems() async {
    final Database db = await open();

    final List<Map<String, dynamic>> maps =
        await db.query('tItem', orderBy: "parent");

    return List.generate(maps.length, (i) {
      return Item.getItem(
        id: maps[i]['id'],
        name: maps[i]['name'],
        isFolder: maps[i]['is_folder'],
        parent: maps[i]['parent'],
      );
    });
  }

  Future<List<ItemData>> getAllItemData() async {
    final Database db = await open();

    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await db.query('tItemData');

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      return ItemData.getItemData(
        id: maps[i]['id'],
        username: maps[i]['username'],
        url: maps[i]['url'],
        password: maps[i]['password'],
        secret: maps[i]['secret'],
        comments: maps[i]['comments'],
        itemId: maps[i]['item_id'],
      );
    });
  }

  Future<void> printItems() async {
    final Database db = await open();

    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await db.query('tItem');

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    List.generate(maps.length, (i) {
      log.i(
          'database_util.dart :: 141 :: name=${maps[i]['name']} :: isFolder=${maps[i]['is_folder']} :: parent=${maps[i]['parent']}');
    });
  }
}

class Item {
  int id = 0;
  String name;
  final int isFolder;
  int parent;

  Item({this.name, this.isFolder, this.parent});
  Item.getItem({this.name, this.isFolder, this.parent, this.id});

  static Item getItemFromMap(Map<String, dynamic> map) {
    return Item(
        name: map['name'], parent: map['parent'], isFolder: map['is_folder']);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'is_folder': isFolder,
      'parent': parent,
    };
  }

  @override
  String toString() {
    return json.encode({
      "id": id,
      "name": name,
      "is_folder": isFolder,
      "parent": parent,
    });
  }

  Map<String, dynamic> toJson() => _toJson(this);

  Map<String, dynamic> _toJson(Item instance) {
    return <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'is_folder': instance.isFolder,
      'parent': instance.parent,
    };
  }
}

class ItemData {
  int id = 0;
  String username;
  String url;
  String password;
  String secret;
  String comments;
  int itemId;

  ItemData(
      {this.username, this.password, this.comments, this.itemId, this.secret, this.url});
  ItemData.getItemData(
      {this.id, this.itemId, this.username, this.password, this.comments, this.secret, this.url});
  static ItemData getItemDataFromMap(Map<String, dynamic> map) {
    return ItemData(
      username: map['username'],
      url: map['url'],
      password: map['password'],
      secret: map['secret'],
      comments: map['comments'],
      itemId: map['item_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'url':url,
      'password': password,
      'secret': secret,
      'comments': comments,
      'item_id': itemId,
    };
  }

  @override
  String toString() {
    return json.encode({
      "id": id,
      "username": username,
      "url": url,
      "password": password,
      "secret": secret,
      "comments": comments,
      "item_id": itemId,
    });
  }

  Map<String, dynamic> toJson() => _toJson(this);

  Map<String, dynamic> _toJson(ItemData instance) {
    return <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'url': instance.url,
      'password': instance.password,
      'secret': instance.secret,
      'comments': instance.comments,
      'item_id': instance.itemId,
    };
  }
}
