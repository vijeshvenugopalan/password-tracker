import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:password_tracker/state/password.dart';
import 'package:provider/provider.dart';

class InitScreen extends StatefulWidget {
  @override
  _InitScreenState createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  Logger log = getLogger('_InitScreenState');
  late Password password;
  static const List<String> screenshots = <String>[
    'icons/initial-setup/screenshot1.png',
    'icons/initial-setup/screenshot2.png',
    'icons/initial-setup/screenshot3.png',
    'icons/initial-setup/screenshot4.png',
    'icons/initial-setup/screenshot5.png',
    'icons/initial-setup/screenshot6.png',
    'icons/initial-setup/screenshot7.png',
    'icons/initial-setup/screenshot8.png',
  ];
  int index = 0;
  Duration timeStamp = Duration();

  @override
  Widget build(BuildContext context) {
    password = Provider.of<Password>(context);
    if (password.isComplete) {
      if (password.password == null || password.password!.isEmpty) {
        return getWidget();
      } else {
        password.initalSetup = true;
        Navigator.pushReplacementNamed(context, "/password");
        return Container(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
        ;
      }
    } else {
      return Container(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }

  SafeArea getWidget() {
    return SafeArea(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          int diff = details.sourceTimeStamp!.inMilliseconds -
              timeStamp.inMilliseconds;
          if (diff < 500) {
            return;
          }
          if (details.delta.dx < -10) {
            timeStamp = details.sourceTimeStamp!;
            increment();
          }
          if (details.delta.dx > 10) {
            timeStamp = details.sourceTimeStamp!;
            decrement();
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Center(
              child: Stack(
                children: getWidgetList(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    decrement();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: Icon(
                    Icons.arrow_left,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    increment();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: Icon(
                    Icons.arrow_right,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> getWidgetList() {
    List<Widget> list = List.filled(0, Container(), growable: true);
    for (var i = 0; i < screenshots.length; i++) {
      list.add(getAnimatedContainer(i));
    }
    return list;
  }

  AnimatedContainer getAnimatedContainer(int index) {
    return AnimatedContainer(
      curve: Curves.easeInOut,
      duration: Duration(
        milliseconds: 300,
      ),
      transform: index > this.index
          ? (Matrix4.identity()
            ..translate(MediaQuery.of(context).size.width + 20, 0))
          : (index < this.index)
              ? (Matrix4.identity()
                ..translate(-MediaQuery.of(context).size.width - 20, 0))
              : Matrix4.identity(),
      child: Image.asset(
        screenshots[index],
      ),
    );
  }

  void increment() {
    setState(() {
      index++;
      if (index >= screenshots.length) {
        index = screenshots.length - 1;
        password.initalSetup = true;
        Navigator.pushReplacementNamed(context, "/password");
      }
      log.i('initial_setup.dart :: 40 :: index = $index');
    });
  }

  void decrement() {
    setState(() {
      index--;
      if (index < 0) {
        index = 0;
      }
      log.i('initial_setup.dart :: 41 :: index = $index');
    });
  }
}
