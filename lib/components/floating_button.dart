import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/services/database_util.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:password_tracker/state/data.dart';
import 'package:password_tracker/utils/add.dart';
import 'package:provider/provider.dart';

class CustomAddButton extends StatefulWidget {
  @override
  _CustomAddButtonState createState() => _CustomAddButtonState();
}

class _CustomAddButtonState extends State<CustomAddButton> with Add {
  final Logger log = getLogger("CustomAddButton");

  createMenu(BuildContext context) {
    return showGeneralDialog(
      barrierLabel: "add",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 300),
      context: context,
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 110,
            color: Theme.of(context).backgroundColor,
            alignment: Alignment.bottomCenter,
            child: Column(
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    log.i('floating_button.dart :: 120 :: Add item');
                    Navigator.pop(context);
                    createAlertDialogue(context, true);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 10,
                        height: 50,
                      ),
                      Icon(
                        Icons.description,
                        color: Theme.of(context)
                            .floatingActionButtonTheme
                            .backgroundColor,
                        size: 25,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text("Create new Item",
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
                    log.i('floating_button.dart :: 138 :: add folder');
                    Navigator.pop(context);
                    createAlertDialogue(context, false);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 10,
                        height: 50,
                      ),
                      Icon(
                        Icons.folder,
                        color: Theme.of(context)
                            .floatingActionButtonTheme
                            .backgroundColor,
                        size: 25,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text("Create new Folder",
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 40,
      child: FloatingActionButton(
        elevation: 0,
        onPressed: () {
          log.i('folder.dart :: On pressed in item button');

          // createAlertDialogue(context);
          createMenu(context);
        },
        child: Icon(
          Icons.add,
          size: 30,
        ),
      ),
    );
  }
}
