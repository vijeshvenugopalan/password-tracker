import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/services/crypto_util.dart';
import 'package:password_tracker/services/database_util.dart';
import 'package:password_tracker/services/logging.dart';

class Data extends ChangeNotifier {
  Logger log = getLogger('Data');
  Map parentMap = Map();
  Map data = Map();
  int currentItemId = 1;
  List<int> stack = List.filled(0, null,growable: true);

  bool _isComplete = false;
  List<Item> _itemList;
  List<ItemData> _itemDataList;

  void setCurrentItemId(int currentItemId, [bool notify = true]) async {
    _isComplete = false;
    if (data.isEmpty) {
      log.i('data.dart :: 22 :: Goint to retrieve data');
      await _retrieveData();
    }
    this.currentItemId = currentItemId;
    _isComplete = true;
    stack.add(currentItemId);
    log.i('data.dart :: 27 :: list = $stack');
    if (notify) {
      notifyListeners();
    }
  }

  int getCurrentItemId() {
    return currentItemId;
  }

  int getParent(int itemId) {
    return parentMap[itemId];
  }

  Map getCurrent() {
    return _getMap(currentItemId);
  }

  Map getMap(int itemId) {
    return _getMap(itemId);
  }

  ItemData getItemData(int itemId) {
    return _getMap(itemId)['data'];
  }

  void getBack() {
    log.i('data.dart :: 32 :: Get back list = $stack');
    stack.removeLast();
    currentItemId = stack.elementAt(stack.length-1);
    // currentItemId = getParent(currentItemId);
    notifyListeners();
  }

  Future<void> _retrieveData() async {
    _itemList = await TrackerDatabase.instance.getAllItems();
    for (Item item in _itemList) {
      // log.i('data.dart :: 46 :: ${item.id} :: ${item.name} :: ${item.parent}');
    }
    for (Item item in _itemList) {
      parentMap[item.id] = item.parent;
      Map map = _getMap(item.id);
      map['item'] = item;
    }

    _itemDataList = await TrackerDatabase.instance.getAllItemData();
    for (var itemData in _itemDataList) {
      Map map = _getMap(itemData.itemId);
      map['data'] = itemData;
    }

    // log.i('data.dart :: 53 :: map = $data');
    // log.i('data.dart :: 49 :: parentMap = $parentMap');
  }

  Map _getMap(int itemId) {
    // log.i('data.dart :: 70 :: getmap item = $itemId');
    if (itemId == 1) {
      Map map = data;
      if (null == map["1"]) {
        map["1"] = Map();
      }
      return map["1"];
    } else {
      Map parent = _getMap(parentMap[itemId]);
      if (parent["$itemId"] == null) {
        parent["$itemId"] = Map();
      }
      return parent["$itemId"];
    }
  }

  // List<Item> get items {
  //   List<Item> tempItems = List<Item>.filled(0, null, growable: true);
  //   Map map = _getMap(currentItemId);
  //   // log.i('data.dart :: 71 :: map = $map');
  //   // log.i('data.dart :: 89 :: parentMap = $parentMap');
  //   for (var key in map.keys) {
  //     if (_isKeyIndex(key)) {
  //       tempItems.add(map[key]['item']);
  //     }
  //   }
  //   return tempItems;
  // }

  List<Item> getItems(int itemId) {
    List<Item> tempItems = List<Item>.filled(0, null, growable: true);
    Map map = _getMap(itemId);
    // log.i('data.dart :: 71 :: map = $map');
    // log.i('data.dart :: 89 :: parentMap = $parentMap');
    for (var key in map.keys) {
      if (_isKeyIndex(key)) {
        tempItems.add(map[key]['item']);
      }
    }
    return tempItems;
  }

  List<Item> getAllItems() {
    return _itemList;
  }

  List<Item> getFolders(int id) {
    List<Item> tempItems = List<Item>.filled(0, null, growable: true);
    Map map = _getMap(id);
    log.i('data.dart :: 108 :: map = $map');
    for (var key in map.keys) {
      if (_isKeyIndex(key)) {
        Item item = map[key]['item'];
        if (item.isFolder == 1) {
          tempItems.add(item);
        }
      }
    }
    return tempItems;
  }

  List<Item> search(String text) {
    if (null == text || text.trim().length == 0) {
      return List.filled(0, null);
    }
    log.i('data.dart :: 121 :: item list = $_itemList');
    return _itemList.where((item) {
      if (item.name.toLowerCase().contains(text)) {
        return true;
      }
      if (item.isFolder == 0) {
        ItemData itemData = _getMap(item.id)['data'];
        if (null != itemData.username &&
            itemData.username.toLowerCase().contains(text)) {
          return true;
        }
        if (null != itemData.url &&
            itemData.url.toLowerCase().contains(text)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  bool _isKeyIndex(var key) {
    return key != "item" && key != "data";
  }

  bool get isComplete {
    return _isComplete;
  }

  Future<void> addItem(Item item) async {
    await _insertItem(item);
  }

  Future<void> _insertItem(Item item) async {
    if (item.id == null || item.id <= 0) {
      _itemList.add(item);
    }
    item.id = await TrackerDatabase.instance.insertItem(item);
    parentMap[item.id] = item.parent;
    Map map = _getMap(item.id);
    map['item'] = item;
    notifyListeners();
  }

  Future<void> addItemData(ItemData itemData) async {
    await _insertItemData(itemData);
  }

  Future<void> _insertItemData(ItemData itemData) async {
    // log.i('data.dart :: 194 :: itemId = ${itemData.id}');
    if (itemData.id == null || itemData.id <=0) {
      _itemDataList.add(itemData);
    }
    itemData.id = await TrackerDatabase.instance.insertItemData(itemData);
    Map map = _getMap(itemData.itemId);
    map['data'] = itemData;
    notifyListeners();
  }

  Future<void> deleteItem(Item item) async {
    log.i('data.dart :: 172 :: Indide delete item ${item.id}');
    await _deleteItem(item);
    log.i('data.dart :: 126 :: Map after delete = $data');
  }

  Future<void> _deleteItem(Item item) async {
    int itemId = item.id;
    int parentId = parentMap[itemId];
    Map itemMap = _getMap(itemId);
    log.i('data.dart :: 182 :: ');
    List<dynamic> keys = List.filled(0, null, growable: true);
    keys.addAll(itemMap.keys);
    if (item.isFolder == 1) {
      for (var key in keys) {
        if (_isKeyIndex(key)) {
          await _deleteItem(itemMap[key]['item']);
        }
      }
    } else {
      ItemData itemData = itemMap['data'];
      _itemDataList.remove(itemData);
      await TrackerDatabase.instance.deleteItemData(itemData);
    }
    await TrackerDatabase.instance.deleteItem(item);
    Map map = _getMap(parentId);
    map.remove("$itemId");
    _itemList.remove(item);
    parentMap.remove(itemId);
  }

  Future<void> moveItem(Item item, int id) async {
    Map map = _getMap(item.parent).remove("${item.id}");
    _getMap(id)["${item.id}"] = map;
    item.parent = id;
    parentMap[item.id] = id;
    await TrackerDatabase.instance.insertItem(item);
  }

  Future<void> reEncryptAll(String newHash, String oldHash) async {
    log.i('data.dart :: 206 :: length = ${_itemDataList.length}');
    for (var i = 0; i < _itemDataList.length; i++) {
      ItemData itemData = _itemDataList.elementAt(i);
      log.i('data.dart :: 220 :: itemData = $itemData');
      if (null != itemData.password) {
        itemData.password = _reEncrypt(itemData.password, newHash, oldHash);
      }
      if (null != itemData.secret) {
        itemData.secret = _reEncrypt(itemData.secret, newHash, oldHash);
      }
      if (null != itemData.comments) {
        itemData.comments = _reEncrypt(itemData.comments, newHash, oldHash);
      }
      log.i('data.dart :: 211 :: Going to save ${itemData.username}');
      await TrackerDatabase.instance.insertItemData(itemData);
    }
  }

  String _reEncrypt(String str, String newHash, String oldHash) {
    String text = PasswordCrypto.instance.decrypt(str, oldHash);
    String encrypted = PasswordCrypto.instance.encrypt(text, newHash);
    return encrypted;
  }
}
