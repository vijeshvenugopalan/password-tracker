import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/services/logging.dart';

class DrawerWidget extends StatefulWidget {
  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {

  Logger log = getLogger('_DrawerWidgetState');
  int navigationIndex = 0;
  List<String> navigationItems = [
    "Home",
    "Change Password",
    "Biometric",
    "Export to file",
    "Import",
    "Import from chrome(csv)"
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      child: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircleAvatar(
                    radius: 40,
                    child: Image(
                      image: AssetImage("icons/icon.png"),
                    ),
                  )
                ],
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: navigationItems.length,
                itemBuilder: (BuildContext context, int index) {
                  String name = navigationItems.elementAt(index);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      InkWell(
                        child: AnimatedContainer(
                          curve: Curves.linear,
                          duration: Duration(
                            milliseconds: 100,
                          ),
                          margin: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          padding:
                              EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.transparent.withOpacity((index==navigationIndex)? 0.2:0.0)),
                          child: Text(
                            name,
                            // style: TextStyle(fontWeight: (index == navigationIndex) ?FontWeight.bold:FontWeight.normal),
                          ),
                          onEnd: () {
                            log.i('drawer.dart :: 71 :: On end of index=$index');
                            if (navigationIndex == index) {
                              _processKeyPressed(name, context);
                            }
                          },
                        ),
                        onTap: () {
                          log.i('drawer.dart :: 102 :: home');
                          setState(() {
                            navigationIndex = index;
                          });
                        },
                      ),
                      Divider(
                        thickness: 1,
                        height: 2,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processKeyPressed(String name, BuildContext context) {
    switch (name) {
      case "Home":
        log.i('drawer.dart :: 102 :: home');
        Navigator.pop(context);
        break;
      case "Change Password":
        log.i('drawer.dart :: 102 :: change password');
        Navigator.pop(context);
        Navigator.pushNamed(context, '/change_password');
        break;
      case "Biometric":
        log.i('drawer.dart :: 108 :: finger print');
        Navigator.pop(context);
        Navigator.pushNamed(context, '/biometric');
        break;
      case "Export to file":
        log.i('drawer.dart :: 108 :: export to file');
        Navigator.pop(context);
        Navigator.pushNamed(context, '/export_file');
        break;
      case "Import":
        log.i('drawer.dart :: 108 :: import');
        Navigator.pop(context);
        Navigator.pushNamed(context, '/import_file');
        break;
      case "Import from chrome(csv)":
        log.i('drawer.dart :: 108 :: import from chrome');
        Navigator.pop(context);
        Navigator.pushNamed(context, '/import_chrome_password');
        break;
      default:
    }
  }
}