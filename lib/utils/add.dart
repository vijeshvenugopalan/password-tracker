import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/services/database_util.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:password_tracker/state/data.dart';
import 'package:provider/provider.dart';

mixin Add {
  Logger log = getLogger('Add');

  createAlertDialogue(BuildContext context, bool isItem, [Item? item]) {
    TextEditingController controller = TextEditingController();
    Data data = Provider.of<Data>(context, listen: false);
    if (null != item) {
      controller.text = item.name!;
    }
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                child: Container(
                  height: 150,
                  color: Colors.transparent,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "Name",
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: TextField(
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          controller: controller,
                          onSubmitted: (value) async {
                            await _onSubmit(
                                context, isItem, item, controller, data);
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(left: 15, top: 20),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                foregroundColor: Theme.of(context)
                                    .buttonTheme
                                    .colorScheme
                                    ?.primary,
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
                              child: Text("Cancel"),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            TextButton(
                              onPressed: () async {
                                await _onSubmit(
                                    context, isItem, item, controller, data);
                              },
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                foregroundColor: Theme.of(context)
                                    .buttonTheme
                                    .colorScheme
                                    ?.primary,
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
                              child: Text("Save"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        });
  }

  Future<void> _onSubmit(BuildContext context, bool isItem, Item? item,
      TextEditingController controller, Data data) async {
    if (controller.text != null && controller.text.trim().length > 0) {
      if (null == item) {
        item = Item(
          isFolder: (isItem) ? 0 : 1,
          name: controller.text.trim(),
          parent: data.getCurrentItemId(),
        );
      }
      item.name = controller.text.trim();
      await data.addItem(item);
      if (isItem) {
        log.i('add.dart :: 67 :: itemid = ${item.id}');
        ItemData itemData = ItemData(itemId: item.id);
        await data.addItemData(itemData);
        log.i('add.dart :: 72 :: itemData id = ${itemData.id}');
      }
      Navigator.pop(context);
    }
  }
}
