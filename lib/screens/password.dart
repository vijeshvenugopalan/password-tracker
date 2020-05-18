import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/services/crypto_util.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:password_tracker/state/data.dart';
import 'package:password_tracker/state/lifecycle_state.dart';
import 'package:password_tracker/state/password.dart';
import 'package:provider/provider.dart';

class PasswordWidget extends StatefulWidget {
  @override
  _PasswordWidgetState createState() => _PasswordWidgetState();
}

Widget getInitScreen() {
  return WillPopScope(
    onWillPop: () async => false,
    child: Scaffold(
      appBar: AppBar(
        title: Text("Password Tracker"),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        child: PasswordWidget(),
      ),
    ),
  );
}

class _PasswordWidgetState extends State<PasswordWidget> {
  Logger log = getLogger('_PasswordWidgetState');
  TextEditingController _passwordFirstController;
  TextEditingController _passwordConfirmController;
  TextEditingController _passwordEntryController;
  FocusNode _passwordConfirmFocusNode;

  String msg = "";
  bool success = true;
  Password password;
  Data data;
  LifecycleState lifecycleState;
  @override
  void initState() {
    super.initState();
    _passwordFirstController = TextEditingController();
    _passwordConfirmController = TextEditingController();
    _passwordEntryController = TextEditingController();
    _passwordConfirmFocusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    _passwordFirstController.dispose();
    _passwordConfirmController.dispose();
    _passwordEntryController.dispose();
    _passwordConfirmFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    password = Provider.of<Password>(context);
    data = Provider.of<Data>(context, listen: false);
    lifecycleState = Provider.of<LifecycleState>(context);

    log.i('password.dart :: 65 :: Inside password screen build');
    log.i('password.dart :: $password');
    log.i('password.dart :: iscomplete=${password.isComplete}');
    if (!password.isComplete) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    if (lifecycleState.state == LifecycleState.resumed) {
      password.passwordHash = null;
    }
    if (password.biometric != null && password.passwordHash == null) {
      // if (false) {
      log.i('password.dart :: 66 :: Biometric registered');
      password.decrypt((status, text) async {
        if (status == 1) {
          log.i('password.dart :: 69 :: Biometric successful auth');
          String encryptedPassword =
              PasswordCrypto.instance.encrypt(text, text);
          if (encryptedPassword == password.password) {
            password.passwordHash = text;
            // data.setCurrentItemId(1);
            // Navigator.pushReplacementNamed(context, '/home');
            _navigate();
          } else {
            log.i(
                'password.dart :: 76 :: Password not matching. so removing biometric');
            password.setBiometric(null);
          }
        } else {
          log.i(
              'password.dart :: 71 :: Error while biometric authentication $text');
          if (text != Password.AUTH_CANCELLED &&
              text != Password.AUTH_ERROR &&
              text != Password.AUTH_FAILED) {
            password.setBiometric(null);
          }
        }
      });
    }

    if (password.password == null || password.password.isEmpty) {
      if (password.initalSetup) {
        return _getFirstEntry();
      } else {
        initialSetupScreen();
        return Center(
          child: CircularProgressIndicator(),
        );
      }
    }
    return _getPasswordEntry();
  }

  Future<void> initialSetupScreen() async {
    await Future.delayed(
      Duration(
        microseconds: 500,
      ),
    );
    Navigator.pushReplacementNamed(context, "/init_setup");
    return Future.value(Void);
  }

  Widget _getPasswordEntry() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height / 10,
          ),
          CircleAvatar(
              radius: 40,
              backgroundColor:
                  Theme.of(context).textTheme.display1.backgroundColor,
              child: Image(
                image: AssetImage("icons/icon.png"),
                fit: BoxFit.fill,
              )),
          SizedBox(
            height: 10,
          ),
          Text(
            msg,
            style: TextStyle(
              color: success ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              textInputAction: TextInputAction.done,
              controller: _passwordEntryController,
              obscureText: true,
              onSubmitted: (value) async {
                log.i('password.dart :: 111 :: onsubmitted entry');
                await _onSubmit();
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                labelText: 'Enter password',
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          FlatButton(
            child: Text("Submit"),
            color: Theme.of(context).buttonTheme.colorScheme.background,
            textColor: Theme.of(context).buttonTheme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () async {
              await _onSubmit();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onSubmit() async {
    log.i('init.dart :: entered password = ${_passwordEntryController.text}');
    String passwordHash =
        PasswordCrypto.instance.hash(_passwordEntryController.text);
    password.passwordHash = passwordHash;
    String encryptedPassword =
        PasswordCrypto.instance.encrypt(passwordHash, passwordHash);
    log.i(
        'password.dart :: encrypted password=$encryptedPassword :: DB password = ${password.password}');

    if (encryptedPassword != password.password) {
      log.i('init.dart :: password not equal');
      setState(() {
        success = false;
        msg = "Password incorrect";
      });
    } else {
      setState(() {
        success = true;
        msg = "Password validation success";
      });
      log.i('init.dart :: Password matching');
      password.passwordHash = passwordHash;
      // data.setCurrentItemId(1);
      // Navigator.pushReplacementNamed(context, "/home");
      _navigate();
    }
  }

  void _navigate() {
    // data.setCurrentItemId(data.currentItemId);
    log.i('password.dart :: 209 :: setting canlaunchpassword');
    lifecycleState.canLaunchPassword = true;
    if (lifecycleState.state == LifecycleState.resumed) {
      Navigator.pop(context);
      lifecycleState.state = LifecycleState.active;
    } else {
      data.setCurrentItemId(1);
      Navigator.pushReplacementNamed(context, "/home");
    }
    // Navigator.pop(context);
    // if (true) {
    //   Navigator.popUntil(context, (value) {
    //     log.i('biometric.dart :: 49 :: value= $value');
    //     return false;
    //   });
    //   return;
    // }
    // if (!Navigator.canPop(context)) {
    //   log.i('password.dart :: 185 :: cannot pop anymore');
    //   Navigator.pushNamed(context, '/home');
    // } else {
    //   log.i('password.dart :: 188 :: Can pop is true');
    // }
  }

  Widget _getFirstEntry() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height / 10,
          ),
          CircleAvatar(
              radius: 40,
              backgroundColor:
                  Theme.of(context).textTheme.display1.backgroundColor,
              child: Image(
                image: AssetImage("icons/icon.png"),
                fit: BoxFit.fill,
              )),
          SizedBox(
            height: 10,
          ),
          Text(
            msg,
            style: TextStyle(
              color: success ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              textInputAction: TextInputAction.next,
              controller: _passwordFirstController,
              obscureText: true,
              onSubmitted: (value) {
                log.i('password.dart :: 191 :: On submitted first');
                FocusScope.of(context).requestFocus(_passwordConfirmFocusNode);
              },
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15)),
                  labelText: 'Enter a new password'),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              focusNode: _passwordConfirmFocusNode,
              textInputAction: TextInputAction.done,
              controller: _passwordConfirmController,
              obscureText: true,
              onSubmitted: (value) async {
                log.i('password.dart :: 218 :: on submitted confirm');
                await _onSubmitFirstEntry();
              },
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15)),
                  labelText: 'Confirm password'),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          FlatButton(
            child: Text("Submit"),
            color: Theme.of(context).buttonTheme.colorScheme.background,
            textColor: Theme.of(context).buttonTheme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () async {
              await _onSubmitFirstEntry();
            },
          )
        ],
      ),
    );
  }

  Future<void> _onSubmitFirstEntry() async {
    log.i(
        "button pressed password=${_passwordFirstController.text} :: confirm password=${_passwordConfirmController.text}");

    if (_passwordConfirmController.text != _passwordFirstController.text) {
      log.i("password not equal");
      setState(() {
        success = false;
        msg = "Password not matching";
      });
    } else {
      setState(() {
        success = true;
        msg = "Master password saved successfully";
      });
      await password.savePasssword(_passwordFirstController.text);
      String passwordHash =
          PasswordCrypto.instance.hash(_passwordFirstController.text);
      password.passwordHash = passwordHash;
      data.setCurrentItemId(1);
      lifecycleState.canLaunchPassword = true;
      Navigator.pushReplacementNamed(context, "/home");
    }
  }
}
