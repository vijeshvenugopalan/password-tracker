import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:password_tracker/screens/biometric.dart';
import 'package:password_tracker/screens/change_password.dart';
import 'package:password_tracker/screens/export_file.dart';
import 'package:password_tracker/screens/folder.dart';
import 'package:password_tracker/screens/folder_move.dart';
import 'package:password_tracker/screens/import_chrome_password.dart';
import 'package:password_tracker/screens/import_file.dart';
import 'package:password_tracker/screens/initial_setup.dart';
import 'package:password_tracker/screens/item.dart';
import 'package:password_tracker/screens/password.dart';
import 'package:password_tracker/screens/search.dart';
import 'package:password_tracker/state/data.dart';
import 'package:password_tracker/state/lifecycle_state.dart';
import 'package:password_tracker/state/move_data.dart';
import 'package:password_tracker/state/password.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Route? onGenerateRoute(RouteSettings settings) {
    Route? page = null;
    switch (settings.name) {
      case "/password":
        page = CupertinoPageRoute(builder: (context) => getInitScreen());
        break;
      case "/home":
        page = CupertinoPageRoute(builder: (context) => Folder(1));
        break;
      case "/item":
        page = CupertinoPageRoute(builder: (context) => ItemWidget());
        break;
      case "/move":
        page = CupertinoPageRoute(builder: (context) => FolderMove());
        break;
      case "/search":
        page = CupertinoPageRoute(builder: (context) => Search());
        break;
      case "/change_password":
        page = CupertinoPageRoute(builder: (context) => ChangePassword());
        break;
      case "/biometric":
        page = CupertinoPageRoute(builder: (context) => Biometric());
        break;
      case "/export_file":
        page = CupertinoPageRoute(builder: (context) => ExportFile());
        break;
      case "/import_file":
        page = CupertinoPageRoute(builder: (context) => ImportFile());
        break;
      case "/import_chrome_password":
        page = CupertinoPageRoute(builder: (context) => ImportChromePassword());
        break;
      case "/init_setup":
        page = CupertinoPageRoute(builder: (context) => InitScreen());
        break;
      case "/testing":
        page = CupertinoPageRoute(builder: (context) => Container());
        break;
    }
    return page;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Password()),
        ChangeNotifierProvider(create: (context) => Data()),
        ChangeNotifierProvider(create: (context) => MoveData()),
        ChangeNotifierProvider(create: (context) => LifecycleState()),
      ],
      child: MaterialApp(
        onGenerateRoute: onGenerateRoute,
        theme: ThemeData(
          toggleableActiveColor: Colors.green,
          // seconda: Colors.white,
          primaryColor: Colors.blue,
          // buttonColor: Colors.blue,
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.blue,
            colorScheme: ColorScheme(
              primary: Colors.white,
              primaryVariant: Colors.white,
              secondary: Colors.white,
              secondaryVariant: Colors.white,
              surface: Colors.white,
              background: Colors.blue,
              error: Colors.white,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Colors.white,
              onBackground: Colors.white,
              onError: Colors.white,
              brightness: Brightness.light,
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
          ),
          backgroundColor: Colors.white,
          brightness: Brightness.light,
          appBarTheme: AppBarTheme(
            color: Colors.white,
            // brightness: Brightness.light,
            iconTheme: IconThemeData(
              color: Colors.blue,
            ),
            titleTextStyle: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          primaryIconTheme: IconThemeData(color: Colors.black87, size: 20),
          iconTheme: IconThemeData(color: Colors.blue[300], size: 40),
          textTheme: TextTheme(
            headline5: TextStyle(
              color: Colors.black,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
            headline6: TextStyle(
              color: Colors.black87,
            ),
            bodyText2: TextStyle(
              color: Colors.black87,
              fontSize: 17,
            ),
            headline4: TextStyle(
              color: Colors.blue[900],
              fontSize: 40,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.grey,
            ),
            headline3: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            headline2: TextStyle(
              color: Colors.black87,
              fontSize: 18,
            ),
            headline1: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.normal,
              fontSize: 15,
            ),
            caption: TextStyle(
              color: Colors.black87,
              fontSize: 12,
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        title: 'Password Tracker App',
        initialRoute: '/password',
        // routes: {
        //   '/password': (context) => getInitScreen(),
        //   '/home': (context) => Folder(1),
        //   '/item': (context) => ItemWidget(),
        //   '/move': (context) => FolderMove(),
        //   '/search': (context) => Search(),
        //   '/change_password': (context) => ChangePassword(),
        //   '/biometric': (context) => Biometric(),
        //   '/export_file': (context) => ExportFile(),
        //   '/import_file': (context) => ImportFile(),
        //   '/import_chrome_password': (context) => ImportChromePassword(),
        //   '/testing': (context) => Container(),
        // },
      ),
    );
  }
}
