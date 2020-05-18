import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/services/crypto_util.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:password_tracker/state/data.dart';
import 'package:password_tracker/state/password.dart';
import 'package:provider/provider.dart';

class ChangePassword extends StatefulWidget {
  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  Logger log = getLogger('_ChangePasswordState');

  TextEditingController _oldPasswordController;
  TextEditingController _newPasswordController;
  TextEditingController _newPasswordConfirmController;
  FocusNode _newPasswordFocusNode;
  FocusNode _newPasswordConfirmFocusNode;

  String msg = "";
  bool status = false;
  Password password;
  Data data;

  @override
  void initState() {
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _newPasswordConfirmController = TextEditingController();
    _newPasswordFocusNode = FocusNode();
    _newPasswordConfirmFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _newPasswordConfirmController.dispose();
    _newPasswordFocusNode.dispose();
    _newPasswordConfirmFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Change Password"),
      ),
      body: _getWidget(),
    );
  }

  Widget _getWidget() {
    data = Provider.of<Data>(context);
    password = Provider.of<Password>(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        if (details.delta.dx > 10) {
          Navigator.pop(context);
        }
      },
      child: SingleChildScrollView(
        
        child: Column(
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height / 10,
            ),
            Center(
              child: (msg.compareTo("") == 0)
                  ? SizedBox.shrink()
                  : Container(
                      width: MediaQuery.of(context).size.width-100,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: (msg.compareTo("WAITING") == 0)
                            ? CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              )
                            : Text(
                                msg,
                                style: TextStyle(
                                  color: status ? Colors.green : Colors.red,
                                ),
                              ),
                      ),
                    ),
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                textInputAction: TextInputAction.next,
                controller: _oldPasswordController,
                obscureText: true,
                onSubmitted: (value) {
                  log.i(
                      'change_password.dart :: 191 :: On submitted old password');
                  FocusScope.of(context).requestFocus(_newPasswordFocusNode);
                },
                decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                    labelText: 'Enter Old Password'),
              ),
            ),
            Divider(
              thickness: 1,
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                textInputAction: TextInputAction.next,
                controller: _newPasswordController,
                focusNode: _newPasswordFocusNode,
                obscureText: true,
                onSubmitted: (value) {
                  log.i(
                      'change_password.dart :: 191 :: On submitted new password');
                  FocusScope.of(context)
                      .requestFocus(_newPasswordConfirmFocusNode);
                },
                decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                    labelText: 'Enter New Password'),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                focusNode: _newPasswordConfirmFocusNode,
                textInputAction: TextInputAction.done,
                controller: _newPasswordConfirmController,
                obscureText: true,
                onSubmitted: (value) async {
                  log.i('change_password.dart :: 218 :: on submitted confirm');
                  await _onSubmit();
                },
                decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                    labelText: 'Confirm New Password'),
              ),
            ),
            Divider(
              thickness: 1,
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
                  if(msg.compareTo("WAITING") == 0){
                    return;
                  }
                  setState(() {
                    status = false;
                    msg = "WAITING";
                  });
                  await _onSubmit();
                },
              ),
            SizedBox(
              height:MediaQuery.of(context).size.height - 100,
            )
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    log.i(
        "button pressed password=${_oldPasswordController.text} :: confirm password=${_newPasswordController.text}");

    if (_newPasswordConfirmController.text != _newPasswordController.text) {
      log.i("New Passwords dont match");
      setState(() {
        status = false;
        msg = "New Password not matching";
      });
    } else {
      String oldHash =
          PasswordCrypto.instance.hash(_oldPasswordController.text);
      if (password.passwordHash != oldHash) {
        setState(() {
          status = false;
          msg = "Old Password provided is wrong";
        });
        return;
      }
      await password.savePasssword(_newPasswordController.text);
      log.i('change_password.dart :: 174 :: ');
      String newHash =
          PasswordCrypto.instance.hash(_newPasswordController.text);
      password.passwordHash = newHash;
      log.i('change_password.dart :: 178 :: ');
      await data.reEncryptAll(newHash, oldHash);
      log.i('change_password.dart :: 180 :: ');
      password.setBiometric(null);
      setState(() {
        status = true;
        msg = "Password changed successful";
      });
      // Navigator.pop(context);
    }
  }
}
