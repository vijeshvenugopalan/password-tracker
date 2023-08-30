import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/components/floating_button.dart';
import 'package:password_tracker/components/list_item.dart';
import 'package:password_tracker/screens/drawer.dart';
import 'package:password_tracker/services/database_util.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:password_tracker/state/data.dart';
import 'package:password_tracker/state/lifecycle_state.dart';
import 'package:password_tracker/state/move_data.dart';
import 'package:password_tracker/state/password.dart';
import 'package:password_tracker/utils/add.dart';
import 'package:provider/provider.dart';

class Folder extends StatefulWidget {
  final int rootId;
  Logger log = getLogger("Folder");
  Folder(this.rootId) {
    log.i('folder.dart :: 20 :: Inside create folder $rootId');
  }

  @override
  _FolderState createState() => _FolderState();
}

class _FolderState extends State<Folder> with Add, WidgetsBindingObserver {
  final Logger log = getLogger('_FolderState');
  bool isSelected = false;
  Data? data;
  MoveData? moveData;
  BuildContext? mainContext;
  static const String move = "Move";
  static const String delete = "Delete";
  List<Item?>? items;
  LifecycleState? lifecycleState;
  // ScrollController _scrollController;
  PageStorageKey? _pageStorageKey;
  Duration timeStamp = Duration();

  static const List<String> choices = <String>[
    move,
    delete,
  ];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log.i('folder.dart :: 34 :: state = $state');
    var routeName = ModalRoute.of(context)?.settings.name;

    log.i('folder.dart :: 52 :: route name = $routeName');
    log.i('folder.dart :: 42 :: state in local = ${lifecycleState?.state}');
    log.i(
        'folder.dart :: 54 :: can launch = ${lifecycleState?.canLaunchPassword}');
    if (!lifecycleState!.canLaunchPassword) {
      return;
    }
    if (state == AppLifecycleState.paused) {
      lifecycleState!.state = LifecycleState.paused;
    } else if (state == AppLifecycleState.resumed) {
      lifecycleState!.state = LifecycleState.resumed;
      _startPin(context);
    }
    // Navigator.popUntil(context, ModalRoute.withName('/home'));
    // Navigator.pushNamed(context, '/password');
    // }
  }

  Future<void> _startPin(BuildContext context) {
    lifecycleState!.canLaunchPassword = false;
    Navigator.pushNamed(context, '/password');
    return Future<Void>.value();
  }

  @override
  initState() {
    log.i('folder.dart :: 65 :: Floder init state');
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _scrollController =
    //     ScrollController(initialScrollOffset: 0.0, keepScrollOffset: false);
    // _scrollController.addListener(_scrollPosition);
    _pageStorageKey = PageStorageKey(widget.rootId);
  }

  // void _scrollPosition() {
  // log.i(
  // 'folder.dart :: 72 :: position = ${_scrollController.position.pixels} :: offset = ${_scrollController.offset}');
  // _scrollController.offset = _scrollController.position.pixels;
  // }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _popScope() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: Text("Do you want to exit the app?"),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text("No"),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor:
                  Theme.of(context).buttonTheme.colorScheme!.background,
              foregroundColor:
                  Theme.of(context).buttonTheme.colorScheme!.primary,
            ),
          ),
          SizedBox(width: 20),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text("Yes"),
            style: TextButton.styleFrom(
              backgroundColor:
                  Theme.of(context).buttonTheme.colorScheme!.background,
              foregroundColor:
                  Theme.of(context).buttonTheme.colorScheme!.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  Future<bool> _popFolder() {
    data!.getBack();
    return new Future<bool>.value(true);
  }

  Future<bool> _onBack() {
    if (isSelected) {
      setState(() {
        isSelected = false;
      });
      return Future<bool>.value(false);
    }
    return (data!.getCurrentItemId() == 1) ? _popScope() : _popFolder();
  }

  Future<bool> _onSwipeLeft() {
    if (isSelected) {
      setState(() {
        isSelected = false;
      });
      return Future<bool>.value(false);
    }
    return (data!.getCurrentItemId() == 1)
        ? Future<bool>.value(false)
        : _popFolder();
  }

  @override
  Widget build(BuildContext context) {
    data = Provider.of<Data>(context);
    moveData = Provider.of<MoveData>(context);
    lifecycleState = Provider.of<LifecycleState>(context);
    log.i('folder.dart :: 44 :: complete = ${data!.isComplete}');
    if (data!.isComplete) {
      // if (data.currentItemId != widget.rootId) {
      //   log.i(
      //       'folder.dart :: 150 :: id = ${data.currentItemId} :: rootId=${widget.rootId}');
      //   log.i('folder.dart :: 150 :: Ids are not equal so just ignore 1');
      //   return Center(child: CircularProgressIndicator());
      // }
      items = data!.getItems(widget!.rootId);
      log.i('folder.dart :: item count = ${items!.length}');
      return WillPopScope(
        onWillPop: _onBack,
        child: Scaffold(
          appBar: AppBar(
            title: _getTitle(),
            actions: _getActions(),
          ),
          drawer: DrawerWidget(),
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) async {
              int diff = details.sourceTimeStamp!.inMilliseconds -
                  timeStamp.inMilliseconds;
              if (diff < 500) {
                return;
              }
              timeStamp = details.sourceTimeStamp!;
              if (details.delta.dx > 10) {
                bool pop = await _onSwipeLeft();
                log.i('folder.dart :: 190 :: pop = $pop');
                if (pop) {
                  Navigator.pop(context);
                }
              }
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(15, 10, 0, 0),
              child: ListView.builder(
                  // controller: _scrollController,

                  key: _pageStorageKey,
                  // key: ValueKey<int>(Random(DateTime.now().millisecondsSinceEpoch).nextInt(4294967296)),
                  itemCount: items?.length,
                  itemBuilder: (
                    BuildContext context,
                    int index,
                  ) {
                    mainContext = context;
                    Item? currentItem = items?.elementAt(index);
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
                                moveData?.clearSelected();
                                moveData?.addSelected(currentItem!.id);
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
                                if (moveData!.isSelected(currentItem.id)) {
                                  moveData!.removeSelected(currentItem.id);
                                } else {
                                  moveData!.addSelected(currentItem.id);
                                }
                                setState(() {});
                              } else {
                                if (currentItem.isFolder == 1) {
                                  data?.setCurrentItemId(currentItem.id);
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          Folder(data!.currentItemId!),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        var begin = Offset(1.0, 0.0);
                                        var end = Offset.zero;
                                        var curve = Curves.ease;

                                        var tween = Tween(
                                                begin: begin, end: end)
                                            .chain(CurveTween(curve: curve));

                                        return SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                  //   MaterialPageRoute(
                                  //       builder: (context) =>
                                  //           Folder(data.currentItemId)),
                                  // );
                                } else {
                                  data?.setCurrentItemId(currentItem.id, false);
                                  navigateItem();
                                }
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      (currentItem!.isFolder == 1)
                                          ? Icon(Icons.folder)
                                          : Icon(Icons.description),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      ListItem(currentItem!),
                                    ],
                                  ),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      log.i(
                                          'folder.dart :: 118 :: tap on more');
                                      if (isSelected) {
                                        if (moveData!
                                            .isSelected(currentItem.id)) {
                                          moveData!
                                              .removeSelected(currentItem.id);
                                        } else {
                                          moveData!.addSelected(currentItem.id);
                                        }
                                        setState(() {});
                                      } else {
                                        createOptionMenu(context, currentItem);
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          right: 10,
                                          left: 20,
                                          top: 10,
                                          bottom: 10),
                                      child: Icon(
                                        _getIcon(currentItem!.id),
                                        color: Theme.of(context)
                                            .primaryIconTheme
                                            .color,
                                        size: Theme.of(context)
                                            .primaryIconTheme
                                            .size,
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
          ),
          floatingActionButton:
              (isSelected) ? SizedBox.shrink() : CustomAddButton(),
        ),
      );
    } else {
      return Center(child: CircularProgressIndicator());
    }
  }

  Future<Void> navigateItem() async {
    Navigator.pushNamed(context, "/item");
    return Future<Void>.value();
  }

  Widget _getTitle() {
    if (isSelected) {
      int count = moveData!.getSelectedCount();
      return Text("$count Selected");
    }
    return (widget.rootId == 1)
        ? Text("Home")
        : Text(data!.getMap(widget.rootId)['item'].name);
  }

  IconData _getIcon(int id) {
    if (isSelected) {
      if (moveData!.isSelected(id)) {
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
      IconButton(
        onPressed: () {
          log.i('folder.dart :: 317 :: pressed on search');
          Navigator.pushNamed(context, '/search');
        },
        icon: Icon(
          Icons.search,
          size: 20,
        ),
      ),
      IconButton(
        onPressed: () {
          log.i('folder.dart :: 326 :: pressed on tick');
          moveData!.clearSelected();
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
          if (items?.length == moveData!.getSelectedCount()) {
            moveData!.clearSelected();
            setState(() {});
          } else {
            for (var item in items!) {
              moveData!.addSelected(item!.id);
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
      (moveData!.getSelectedCount() > 0)
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
        moveData!.setCurrentItemId(1);
        await Navigator.pushNamed(context, '/move');
        break;
      case delete:
        log.i('folder.dart :: 388 :: delete switch');
        await moveData!.deleteItems(data!);
        final snackBar = SnackBar(
          content: Text("Selected items Deleted"),
          duration: Duration(seconds: 1),
        );
        ScaffoldMessenger.of(mainContext!).showSnackBar(snackBar);
        break;
      default:
    }
    if (moveData!.getSelectedCount() == 0) {
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
                    moveData!.clearSelected();
                    moveData!.addSelected(item.id);
                    moveData!.setCurrentItemId(1);
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
                    moveData!.clearSelected();
                    moveData!.addSelected(item.id);
                    await moveData!.deleteItems(data!);
                    Navigator.pop(context);
                    final snackBar = SnackBar(
                      content: Text("Deleted ${item.name}"),
                      duration: Duration(seconds: 1),
                    );
                    ScaffoldMessenger.of(mainContext!).showSnackBar(snackBar);
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
