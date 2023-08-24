import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/components/floating_button.dart';
import 'package:password_tracker/components/list_item.dart';
import 'package:password_tracker/screens/folder.dart';
import 'package:password_tracker/services/database_util.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:password_tracker/state/data.dart';
import 'package:password_tracker/state/move_data.dart';
import 'package:password_tracker/utils/add.dart';
import 'package:provider/provider.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> with Add {
  final Logger log = getLogger('_SearchState');
  bool isSelected = false;
  late Data data;
  late MoveData moveData;
  late BuildContext mainContext;
  static const String move = "Move";
  static const String delete = "Delete";
  late List<Item?> items;
  late TextEditingController controller;

  static const List<String> choices = <String>[
    move,
    delete,
  ];

  @override
  void initState() {
    controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    data = Provider.of<Data>(context);
    moveData = Provider.of<MoveData>(context);
    log.i('folder.dart :: 44 :: complete = ${data.isComplete}');
    if (data.isComplete) {
      log.i('search.dart :: 38 :: search text = ${controller.text}');
      items = data.search(controller.text);
      log.i('folder.dart :: item count = ${items.length}');
      return Scaffold(
        appBar: AppBar(
          title: SizedBox.shrink(),
          actions: _getActions(),
        ),
        body: Padding(
          padding: EdgeInsets.fromLTRB(15, 10, 0, 0),
          child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                mainContext = context;
                Item? currentItem = items.elementAt(index);
                return GestureDetector(
                  onLongPress: () {
                    log.i('folder.dart :: 79 :: on long press');
                  },
                  child: Column(
                    children: <Widget>[
                      InkWell(
                        onLongPress: () {
                          log.i('folder.dart :: 88 :: on long press');
                          if (!isSelected) {
                            moveData.clearSelected();
                            moveData.addSelected(currentItem!.id);
                            setState(() {
                              isSelected = true;
                            });
                          }
                        },
                        onTap: () {
                          log.i('folder.dart :: On tap on index=$index');
                          log.i(
                              'folder.dart :: 71 :: id = ${currentItem!.isFolder}');
                          if (isSelected) {
                            if (moveData.isSelected(currentItem!.id)) {
                              moveData.removeSelected(currentItem.id);
                            } else {
                              moveData.addSelected(currentItem.id);
                            }
                            setState(() {});
                          } else {
                            if (currentItem!.isFolder == 1) {
                              data.setCurrentItemId(currentItem.id);
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      Folder(data.currentItemId!),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    var begin = Offset(1.0, 0.0);
                                    var end = Offset.zero;
                                    var curve = Curves.ease;

                                    var tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));

                                    return SlideTransition(
                                      position: animation.drive(tween),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            } else {
                              data.setCurrentItemId(currentItem.id, false);
                              Navigator.pop(context);
                              Navigator.pushNamed(context, "/item");
                            }
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  (currentItem!.isFolder == 1)
                                      ? Icon(Icons.folder)
                                      : Icon(Icons.description),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  ListItem(currentItem),
                                ],
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  log.i('folder.dart :: 118 :: tap on more');
                                  if (isSelected) {
                                    if (moveData.isSelected(currentItem.id)) {
                                      moveData.removeSelected(currentItem.id);
                                    } else {
                                      moveData.addSelected(currentItem.id);
                                    }
                                    setState(() {});
                                  } else {
                                    createOptionMenu(context, currentItem);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      right: 10, left: 20, top: 10, bottom: 10),
                                  child: Icon(
                                    _getIcon(currentItem.id),
                                    color: Theme.of(context)
                                        .primaryIconTheme
                                        .color,
                                    size:
                                        Theme.of(context).primaryIconTheme.size,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        height: 0,
                        thickness: 0.5,
                        indent: 50,
                      ),
                    ],
                  ),
                );
              }),
        ),
      );
    } else {
      return Center(child: CircularProgressIndicator());
    }
  }

  IconData _getIcon(int id) {
    if (isSelected) {
      if (moveData.isSelected(id)) {
        return Icons.check_box;
      } else {
        return Icons.check_box_outline_blank;
      }
    } else {
      return Icons.more_vert;
    }
  }

  List<Widget> _getActions() {
    if (isSelected) {
      return _getSelectedAction();
    } else {
      return _getNormalAction();
    }
  }

  List<Widget> _getNormalAction() {
    return <Widget>[
      Container(
        width: MediaQuery.of(context).size.width - 150,
        height: 40,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            controller: controller,
            autofocus: true,
            onChanged: (value) {
              log.i('folder.dart :: 360 :: search text = $value');
              setState(() {});
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              labelText: 'Search',
            ),
          ),
        ),
      ),
      IconButton(
        onPressed: () {
          log.i('folder.dart :: 326 :: pressed on tick');
          moveData.clearSelected();
          setState(() {
            isSelected = true;
          });
        },
        icon: Icon(
          Icons.done_outline,
          size: 20,
        ),
      ),
      SizedBox(
        width: 10,
      ),
    ];
  }

  List<Widget> _getSelectedAction() {
    return <Widget>[
      IconButton(
        onPressed: () {
          log.i('folder.dart :: 346 :: pressed on double tick');
          if (items.length == moveData.getSelectedCount()) {
            moveData.clearSelected();
            setState(() {});
          } else {
            for (var item in items) {
              moveData.addSelected(item!.id);
            }
            setState(() {});
          }
        },
        icon: Icon(
          Icons.done_all,
          size: 20,
        ),
      ),
      SizedBox(
        width: 10,
      ),
      (moveData.getSelectedCount() > 0)
          ? PopupMenuButton(
              onSelected: (choice) async {
                await choiceAction(choice);
              },
              itemBuilder: (context) {
                return choices.map((String choice) {
                  return PopupMenuItem(value: choice, child: Text(choice));
                }).toList();
              },
            )
          : SizedBox.shrink(),
    ];
  }

  Future<void> choiceAction(String choice) async {
    log.i('home.dart :: 39 :: choice = $choice');
    switch (choice) {
      case move:
        log.i('folder.dart :: 383 :: move switch');
        moveData.setCurrentItemId(1);
        await Navigator.pushNamed(context, '/move');
        break;
      case delete:
        log.i('folder.dart :: 388 :: delete switch');
        await moveData.deleteItems(data);
        final snackBar = SnackBar(
          content: Text("Selected items Deleted"),
          duration: Duration(seconds: 1),
        );
        ScaffoldMessenger.of(mainContext).showSnackBar(snackBar);
        break;
      default:
    }
    if (moveData.getSelectedCount() == 0) {
      setState(() {
        isSelected = false;
      });
    }
  }

  createOptionMenu(BuildContext context, Item item) {
    return showGeneralDialog(
      barrierLabel: "option",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 300),
      context: context,
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 160,
            color: Theme.of(context).backgroundColor,
            alignment: Alignment.bottomCenter,
            child: Column(
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    log.i('folder.dart :: 172 :: rename');
                    Navigator.pop(context);
                    createAlertDialogue(context, false, item);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 10,
                        height: 50,
                      ),
                      Icon(
                        Icons.edit,
                        color: Theme.of(context)
                            .floatingActionButtonTheme
                            .backgroundColor,
                        size: 25,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text("Rename",
                          style: Theme.of(context).textTheme.bodyText2),
                    ],
                  ),
                ),
                Divider(
                  thickness: 0.5,
                  height: 0,
                ),
                GestureDetector(
                  onTap: () {
                    log.i('folder.dart :: 202 :: move');
                    moveData.clearSelected();
                    moveData.addSelected(item.id);
                    moveData.setCurrentItemId(1);
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/move');
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 10,
                        height: 50,
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: Theme.of(context)
                            .floatingActionButtonTheme
                            .backgroundColor,
                        size: 25,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text("Move",
                          style: Theme.of(context).textTheme.bodyText2),
                    ],
                  ),
                ),
                Divider(
                  thickness: 0.5,
                  height: 0,
                ),
                GestureDetector(
                  onTap: () async {
                    log.i('folder.dart :: 232 :: delete');
                    moveData.clearSelected();
                    moveData.addSelected(item.id);
                    await moveData.deleteItems(data);
                    Navigator.pop(context);
                    final snackBar = SnackBar(
                      content: Text("Deleted ${item.name}"),
                      duration: Duration(seconds: 1),
                    );
                    ScaffoldMessenger.of(mainContext).showSnackBar(snackBar);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 10,
                        height: 50,
                      ),
                      Icon(
                        Icons.delete,
                        color: Theme.of(context)
                            .floatingActionButtonTheme
                            .backgroundColor,
                        size: 25,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text("Delete",
                          style: Theme.of(context).textTheme.bodyText2),
                    ],
                  ),
                ),
                Divider(
                  thickness: 0.5,
                  height: 0,
                ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position:
              Tween(begin: Offset(0, 1), end: Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
    );
  }
}
