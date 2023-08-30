import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/services/database_util.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:password_tracker/state/data.dart';

class MoveData extends ChangeNotifier {
  Logger log = getLogger('MoveData');
  int currentItemId = 1;
  List<int?> selectedList = List<int?>.filled(0, null, growable: true);

  void clearSelected() {
    selectedList.clear();
  }

  void addSelected(int id) {
    if (!selectedList.contains(id)) {
      selectedList.add(id);
    }
  }

  void removeSelected(int id) {
    selectedList.remove(id);
  }

  bool isSelected(int id) {
    return selectedList.contains(id);
  }

  int getSelectedCount() {
    return selectedList.length;
  }

  void setCurrentItemId(int currentItemId) {
    this.currentItemId = currentItemId;
    notifyListeners();
  }

  int getCurrentItemId() {
    return currentItemId;
  }

  void getBack(Data data) {
    log.i('move_data.dart :: 32 :: Get back');
    setCurrentItemId(data.getParent(currentItemId));
  }

  List<Item?> getFolders(Data data) {
    List<Item?> list = data.getFolders(currentItemId);
    return list.where((item) {
      return (!selectedList.contains(item?.id));
    }).toList();
  }

  Future<void> moveItem(Data data) async {
    var allItems = data.getAllItems();
    for (var item in allItems!) {
      if (selectedList.contains(item.id)) {
        log.i('move_data.dart :: 34 :: Move ${item.name} to $currentItemId');
        await data.moveItem(item, currentItemId);
      }
    }
    clearSelected();
  }

  Future<void> deleteItems(Data data) async {
    var allItems = data.getAllItems();
    List<Item?> items = List.filled(0, null, growable: true);
    items.addAll(allItems!);
    log.i('move_data.dart :: 68 :: item length = ${items.length}');
    // log.i('move_data.dart :: 67 :: Inside deleteItems ${allItems.length}');
    log.i('move_data.dart :: 68 :: selected items = $selectedList');
    for (var i = 0; i < items.length; i++) {
      Item? item = items.elementAt(i);
      if (selectedList.contains(item?.id)) {
        log.i('move_data.dart :: 69 :: delete ${item?.name}');
        await data.deleteItem(item);
      }
    }
    clearSelected();
    notifyListeners();
  }
}
