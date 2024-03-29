import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/services/crypto_util.dart';
import 'package:password_tracker/services/database_util.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:password_tracker/state/data.dart';
import 'package:password_tracker/state/lifecycle_state.dart';
import 'package:password_tracker/state/move_data.dart';
import 'package:password_tracker/state/password.dart';
import 'package:password_tracker/utils/storage_perm.dart';
import 'package:provider/provider.dart';

class ImportFile extends StatefulWidget {
  @override
  _ImportFileState createState() => _ImportFileState();
}

class _ImportFileState extends State<ImportFile> with StoragePerm {
  Logger log = getLogger('ImportFileState');

  String msg = "";
  bool success = false;
  late MoveData moveData;
  late Data data;
  late LifecycleState lifecycleState;
  late TextEditingController _passwordController;
  late Password password;
  String? passwordHash;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    moveData = Provider.of<MoveData>(context, listen: false);
    data = Provider.of<Data>(context, listen: false);
    lifecycleState = Provider.of<LifecycleState>(context, listen: false);
    password = Provider.of<Password>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text("Import from File"),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          if (details.delta.dx > 10) {
            Navigator.pop(context);
          }
        },
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: RichText(
                  text: TextSpan(
                    text: 'Import a file generated by Password Tracker itself',
                    style: Theme.of(context).textTheme.headline2,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                textInputAction: TextInputAction.next,
                controller: _passwordController,
                obscureText: true,
                onSubmitted: (value) {
                  log.i('import_file.dart :: 65 :: on submit on password');
                },
                decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                    labelText: 'Password of the file to be imported'),
              ),
            ),
            Center(
              child: ElevatedButton(
                child: Text("Import from file"),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).buttonTheme.colorScheme!.background,
                  foregroundColor:
                      Theme.of(context).buttonTheme.colorScheme!.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  lifecycleState.canLaunchPassword = false;
                  await getPermissions();
                  log.i('import_file.dart :: 24 :: key pressed');
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles();
                  File? file;
                  if (result != null) {
                    file = File(result.files.single.path!);
                  }
                  lifecycleState.canLaunchPassword = true;
                  setState(() {
                    msg = "WAITING";
                  });
                  if (null != file) {
                    log.i('import_file.dart :: 33 :: path = ${file.path}');
                    String fileStr = file.readAsStringSync();
                    log.i('import_file.dart :: 56 :: fileStr = $fileStr');

                    if (null != _passwordController.text &&
                        _passwordController.text.trim().length > 0) {
                      passwordHash = PasswordCrypto.instance
                          .hash(_passwordController.text.trim());
                    } else {
                      passwordHash = null;
                    }

                    String result = await _selectFileAndFolder(fileStr);
                    if (result == "SUCCESS") {
                      setState(() {
                        success = true;
                        msg = "File import successful";
                      });
                    } else {
                      setState(() {
                        success = false;
                        msg = result;
                      });
                    }
                  } else {
                    setState(() {
                      success = false;
                      msg = "File selection failed";
                    });
                  }
                },
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Center(
              child: (msg.compareTo("") == 0)
                  ? SizedBox.shrink()
                  : Container(
                      width: 200,
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
                                  color: success ? Colors.green : Colors.red,
                                ),
                              ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _selectFileAndFolder(String fileStr) async {
    try {
      moveData.clearSelected();
      moveData.setCurrentItemId(1);
      var result = await Navigator.pushNamed(context, '/move');

      if (null == result) {
        return Future<String>.value("No folder selected for import");
      } else {
        Map<String, dynamic> map = json.decode(fileStr);
        log.i('import_file.dart :: 60 :: keys = ${map}');
        log.i('import_file.dart :: 98 :: result = $result');
        try {
          String status = await _parse(map["1"], result as int, false);
          log.i('import_file.dart :: 148 :: status = $status');
          if (status == "SUCCESS") {
            await _parse(map["1"], result, true);
          }
        } catch (e) {
          log.i('import_file.dart :: 159 :: Exception while parsing');
          return Future<String>.value(
              "Password used in file is different from one provided");
        }
        //  value = map["1"]["2"]["item"];
        // log.i('import_file.dart :: 101 :: value = $value');
      }
      log.i('import_file.dart :: 95 :: result = $result');

      return Future<String>.value("SUCCESS");
    } catch (e) {
      log.i('import_file.dart :: 73 :: $e');
      return Future<String>.value("Error while parsing the file data");
    }
  }

  Future<String> _parse(Map<String, dynamic> map, int parent, bool save) async {
    log.i('import_file.dart :: 111 :: maps inside = $map :: parent=$parent');
    bool decryptStatus = false;
    for (var key in map.keys) {
      if (_isKeyIndex(key)) {
        Item item = Item.getItemFromMap(map[key]['item']);
        item.parent = parent;
        if (save) {
          await data.addItem(item);
        }
        int id = map[key]['item']['id'];
        log.i('import_file.dart :: 120 :: item = $item');
        if (item.isFolder == 1) {
          await _parse(map["$id"], item.id, save);
        } else {
          ItemData itemData = ItemData.getItemDataFromMap(map[key]['data']);
          itemData.itemId = item.id;
          if (save) {
            itemData.password = _reEncrypt(itemData.password);
            itemData.secret = _reEncrypt(itemData.secret);
            itemData.comments = _reEncrypt(itemData.comments);
            await data.addItemData(itemData);
          } else {
            // try {
            if (!decryptStatus) {
              decryptStatus = _decrypt(itemData.password);
              decryptStatus = decryptStatus || _decrypt(itemData.secret);
              decryptStatus = decryptStatus || _decrypt(itemData.comments);
            }
            // }catch(e) {
            //   log.i('import_file.dart :: 186 :: Exception while decrypting');
            //   return Future<String>.value("Password for the file imported is not correct");
            // }
          }
          log.i('import_file.dart :: 125 :: itemData = $itemData');
        }
      }
    }
    return Future<String>.value("SUCCESS");
  }

  bool _decrypt(String? encrypted) {
    if (null != encrypted && encrypted.trim().length > 0) {
      PasswordCrypto.instance.decrypt(encrypted, _getPasswordHash()!);
      return true;
    } else {
      return false;
    }
  }

  String? _reEncrypt(String? encrypted) {
    if (null != encrypted && encrypted.trim().length > 0) {
      if (null != passwordHash && passwordHash!.trim().length > 0) {
        String decrypted =
            PasswordCrypto.instance.decrypt(encrypted, passwordHash!);
        return PasswordCrypto.instance
            .encrypt(decrypted, password.passwordHash!);
      }
    }
    return encrypted;
  }

  String? _getPasswordHash() {
    if (null != passwordHash) {
      return passwordHash;
    } else {
      return password.passwordHash;
    }
  }

  bool _isKeyIndex(var key) {
    return key != "item" && key != "data";
  }
}
