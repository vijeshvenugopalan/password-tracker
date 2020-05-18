import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/services/database_util.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:password_tracker/state/data.dart';
import 'package:password_tracker/state/move_data.dart';
import 'package:password_tracker/utils/add.dart';
import 'package:provider/provider.dart';

class FolderMove extends StatefulWidget {
  @override
  _FolderMoveState createState() => _FolderMoveState();
}

class _FolderMoveState extends State<FolderMove> with Add {
  final Logger log = getLogger('_FolderMoveState');
  Data data;
  MoveData moveData;
  Duration timeStamp = Duration();

  Future<bool> _popScope() async {
    return new Future<bool>.value(true);
  }

  Future<bool> _popFolder() {
    moveData.getBack(data);
    return new Future<bool>.value(false);
  }

  Future<bool> _onSwipeLeft() {
    if (moveData.getCurrentItemId() != 1) {
      moveData.getBack(data);
      return new Future<bool>.value(false);
    } else {
      return new Future<bool>.value(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    data = Provider.of<Data>(context, listen: false);
    moveData = Provider.of<MoveData>(context);
    log.i('folder_move.dart :: 44 :: complete = ${data.isComplete}');
    List<Item> items = moveData.getFolders(data);
    log.i('folder_move.dart :: item count = ${items.length}');
    return WillPopScope(
      onWillPop: (moveData.getCurrentItemId() == 1) ? _popScope : _popFolder,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Move to"),
          actions: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: FlatButton(
                onPressed: () async {
                  log.i('folder_move.dart :: 46 :: Move to the folder');
                  if (moveData.getSelectedCount() == 0) {
                    log.i(
                        'folder_move.dart :: 48 :: selected items are 0 so act as folder picker');
                    Navigator.pop(context, moveData.getCurrentItemId());
                  } else {
                    await moveData.moveItem(data);
                    Navigator.pop(context);
                  }
                },
                child: Text("Move"),
                color: Theme.of(context).buttonTheme.colorScheme.background,
                textColor: Theme.of(context).buttonTheme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            SizedBox(
              width: 10,
            ),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) async {
            int diff = details.sourceTimeStamp.inMilliseconds -
                timeStamp.inMilliseconds;
            if (diff < 500) {
              return;
            }
            timeStamp = details.sourceTimeStamp;
            if (details.delta.dx > 10) {
              bool pop = await _onSwipeLeft();
              if (pop) {
                Navigator.pop(context);
              }
            }
          },
          child: Padding(
            padding: EdgeInsets.fromLTRB(15, 10, 0, 0),
            child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  Item currentItem = items.elementAt(index);
                  return GestureDetector(
                    child: Column(
                      children: <Widget>[
                        InkWell(
                          onTap: () {
                            log.i('folder_move.dart :: On tap on index=$index');
                            log.i(
                                'folder_move.dart :: 71 :: id = ${currentItem.isFolder}');
                            moveData.setCurrentItemId(currentItem.id);
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
                                    Icon(Icons.folder),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width -
                                          115,
                                      child: Text(
                                        "${currentItem.name}",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }
}
