import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/services/crypto_util.dart';
import 'package:password_tracker/services/database_util.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:password_tracker/state/data.dart';
import 'package:password_tracker/state/password.dart';
import 'package:provider/provider.dart';

class ItemWidget extends StatefulWidget {
  @override
  _ItemWidgetState createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget> {
  Logger log = getLogger('ItemWidgetState');
  late Data data;
  late Password password;
  bool passwordEnable = false;
  bool commentsEnable = false;
  bool secretEnable = false;
  bool isFirst = true;
  bool isModified = false;
  late ItemData itemData;

  late TextEditingController _controllerUsername;
  late TextEditingController _controllerUrl;
  late TextEditingController _controllerPassword;
  late TextEditingController _controllerSecret;
  late TextEditingController _controllerComments;

  @override
  void initState() {
    super.initState();
    _controllerUsername = TextEditingController();
    _controllerUrl = TextEditingController();
    _controllerPassword = TextEditingController();
    _controllerSecret = TextEditingController();
    _controllerComments = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _controllerUsername.dispose();
    _controllerUrl.dispose();
    _controllerSecret.dispose();
    _controllerPassword.dispose();
    _controllerComments.dispose();
  }

  void _clean() {
    passwordEnable = false;
    secretEnable = false;
    commentsEnable = false;
    isFirst = true;
  }

  Future<bool> _popScope() async {
    if (isModified) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).backgroundColor,
          title: Text("Unsaved changes will be lost?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text("Stay"),
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
            SizedBox(width: 20),
            TextButton(
              onPressed: () {
                data.getBack();
                Navigator.pop(context, true);
              },
              child: Text("Leave"),
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
    } else {
      data.getBack();
      return new Future<bool>.value(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    data = Provider.of<Data>(context, listen: false);
    password = Provider.of<Password>(context, listen: false);
    var current = data.getCurrent();
    itemData = current['data'];
    if (isFirst) {
      _controllerUsername.text = itemData.username ?? '';
      log.i(
          'item.dart :: 55 :: password = ${itemData.password} :: hash = ${password.passwordHash}');
      _controllerPassword.text = itemData.password ?? '';
      _controllerUrl.text = itemData.url ?? '';
      _controllerSecret.text = itemData.secret ?? '';
      _controllerComments.text = itemData.comments ?? '';
      if (null == _controllerSecret.text ||
          _controllerSecret.text.length <= 0) {
        secretEnable = true;
      }
      if (null == _controllerPassword.text ||
          _controllerPassword.text.length <= 0) {
        passwordEnable = true;
      }
      if (null == _controllerComments.text ||
          _controllerComments.text.length <= 0) {
        commentsEnable = true;
      }
      isFirst = false;
    }
    return WillPopScope(
      onWillPop: _popScope,
      child: Scaffold(
        appBar: AppBar(
          title: Text(data.getCurrent()['item'].name),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) async {
            if (details.delta.dx > 10) {
              bool pop = await _popScope();
              if (pop) {
                Navigator.pop(context);
              }
            }
          },
          child: Padding(
            padding: EdgeInsets.only(
              left: 10,
              right: 10,
              top: 10,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 10,
                  ),
                  TextField(
                    onChanged: (value) {
                      isModified = true;
                    },
                    controller: _controllerUsername,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.only(left: 15),
                      border: OutlineInputBorder(),
                      labelText: 'Username',
                    ),
                  ),
                  Divider(
                    height: 10,
                    thickness: 1,
                  ),
                  TextField(
                    onChanged: (value) {
                      isModified = true;
                    },
                    controller: _controllerUrl,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.only(left: 15),
                      border: OutlineInputBorder(),
                      labelText: 'Url',
                    ),
                  ),
                  Divider(
                    height: 10,
                    thickness: 1,
                  ),
                  _getSecretWidget(
                    context: context,
                    controller: _controllerPassword,
                    text: "Password",
                    isEnabled: passwordEnable,
                    onPressed: () {
                      log.i(
                          'item.dart :: 176 :: text =${_controllerPassword.text}');
                      if (null != _controllerPassword.text &&
                          _controllerPassword.text.length > 0) {
                        if (passwordEnable) {
                          log.i('item.dart :: 178 :: Going to encrypt');
                          _controllerPassword.text = PasswordCrypto.instance
                              .encrypt(_controllerPassword.text,
                                  password.passwordHash!);
                        } else {
                          log.i('item.dart :: 178 :: Going to decrypt');
                          _controllerPassword.text = PasswordCrypto.instance
                              .decrypt(_controllerPassword.text,
                                  password.passwordHash!);
                        }
                      }
                      setState(() {
                        passwordEnable = !passwordEnable;
                      });
                    },
                  ),
                  Divider(
                    thickness: 1,
                    height: 10,
                  ),
                  _getSecretWidget(
                    context: context,
                    controller: _controllerSecret,
                    text: "Secret",
                    isEnabled: secretEnable,
                    onPressed: () {
                      log.i(
                          'item.dart :: 188 :: text =${_controllerSecret.text}');
                      if (null != _controllerSecret.text &&
                          _controllerSecret.text.length > 0) {
                        if (secretEnable) {
                          log.i('item.dart :: 192 :: Going to encrypt');
                          _controllerSecret.text = PasswordCrypto.instance
                              .encrypt(_controllerSecret.text,
                                  password.passwordHash!);
                        } else {
                          log.i('item.dart :: 197 :: Going to decrypt');
                          _controllerSecret.text = PasswordCrypto.instance
                              .decrypt(_controllerSecret.text,
                                  password.passwordHash!);
                        }
                      }
                      setState(() {
                        secretEnable = !secretEnable;
                      });
                    },
                  ),
                  Divider(
                    thickness: 1,
                    height: 10,
                  ),
                  _getSecretWidget(
                    context: context,
                    controller: _controllerComments,
                    text: "Comments",
                    isEnabled: commentsEnable,
                    onPressed: () {
                      log.i(
                          'item.dart :: 137 :: text =${_controllerComments.text}');
                      if (null != _controllerComments.text &&
                          _controllerComments.text.length > 0) {
                        if (commentsEnable) {
                          log.i('item.dart :: 141 :: Going to encrypt');
                          _controllerComments.text = PasswordCrypto.instance
                              .encrypt(_controllerComments.text,
                                  password.passwordHash!);
                        } else {
                          log.i('item.dart :: 141 :: Going to decrypt');
                          _controllerComments.text = PasswordCrypto.instance
                              .decrypt(_controllerComments.text,
                                  password.passwordHash!);
                        }
                      }
                      setState(
                        () {
                          commentsEnable = !commentsEnable;
                        },
                      );
                    },
                    minLines: 4,
                    maxLines: 50,
                  ),
                  Divider(
                    height: 10,
                    thickness: 1,
                  ),
                  ElevatedButton(
                      child: Text("Save"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                      onPressed: () async {
                        log.i('item_add.dart :: 85 :: Submit pressed');
                        log.i(
                            'item.dart :: 109 :: password = ${_controllerPassword.text}');
                        if (null != _controllerPassword.text &&
                            (_controllerPassword.text.isNotEmpty)) {
                          if (passwordEnable) {
                            itemData.password = PasswordCrypto.instance.encrypt(
                                _controllerPassword.text,
                                password.passwordHash!);
                          } else {
                            itemData.password = _controllerPassword.text;
                          }
                          log.i(
                              'item.dart :: 111 :: enrtypted password =${itemData.password}');
                        } else {
                          itemData.password = null;
                        }
                        if (null != _controllerSecret.text &&
                            (_controllerSecret.text.isNotEmpty)) {
                          if (secretEnable) {
                            itemData.secret = PasswordCrypto.instance.encrypt(
                                _controllerSecret.text, password.passwordHash!);
                          } else {
                            itemData.secret = _controllerSecret.text;
                          }
                          log.i(
                              'item.dart :: 111 :: enrtypted secret =${itemData.secret}');
                        } else {
                          itemData.secret = null;
                        }
                        if (null != _controllerComments.text &&
                            (_controllerComments.text.isNotEmpty)) {
                          if (commentsEnable) {
                            itemData.comments = PasswordCrypto.instance.encrypt(
                                _controllerComments.text,
                                password.passwordHash!);
                          } else {
                            itemData.comments = _controllerComments.text;
                          }
                          log.i(
                              'item.dart :: 111 :: enrtypted comments =${itemData.comments}');
                        } else {
                          itemData.comments = null;
                        }
                        if (null != _controllerUsername.text &&
                            (_controllerUsername.text.isNotEmpty)) {
                          itemData.username = _controllerUsername.text;
                        } else {
                          itemData.username = null;
                        }
                        if (null != _controllerUrl.text &&
                            (_controllerUrl.text.isNotEmpty)) {
                          itemData.url = _controllerUrl.text;
                        } else {
                          itemData.url = null;
                        }
                        await data.addItemData(itemData);
                        data.getBack();
                        _clean();
                        Navigator.pop(context);
                      }),
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 300,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getSecretWidget(
      {BuildContext? context,
      TextEditingController? controller,
      String text = '',
      bool isEnabled = false,
      required Function() onPressed,
      int minLines = 1,
      int maxLines = 1}) {
    if (!isEnabled) {
      minLines = 1;
      maxLines = 1;
    }
    return Builder(builder: (BuildContext context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: MediaQuery.of(context).size.width - 50,
            child: TextField(
              onChanged: (value) {
                isModified = true;
              },
              obscureText: !isEnabled,
              enabled: isEnabled,
              minLines: minLines,
              maxLines: maxLines,
              controller: controller,
              decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(left: 15, top: 20),
                  border: OutlineInputBorder(),
                  labelText: text),
            ),
          ),
          Container(
            height: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                _getIconContainer(
                  (isEnabled) ? Icons.visibility_off : Icons.visibility,
                  onPressed,
                ),
                _getIconContainer(Icons.content_copy, () {
                  String text;
                  if (isEnabled) {
                    text = controller!.text;
                  } else {
                    text = PasswordCrypto.instance
                        .decrypt(controller!.text, password.passwordHash!);
                  }
                  log.i('item.dart :: 257 :: clipboard text = $text');
                  Clipboard.setData(ClipboardData(text: text));
                  final snackBar = SnackBar(
                    content: Text("Copied text to clipboard"),
                    duration: Duration(seconds: 1),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }),
              ],
            ),
          ),
        ],
      );
    });
  }

  Container _getIconContainer(IconData iconData, Function() onPressed) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 1,
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(5),
        ),
      ),
      child: InkWell(
        child: Icon(
          iconData,
          size: 20,
        ),
        onTap: onPressed,
      ),
    );
  }
}
