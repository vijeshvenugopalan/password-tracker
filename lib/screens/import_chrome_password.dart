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

class ImportChromePassword extends StatefulWidget {
  @override
  _ImportChromePasswordState createState() => _ImportChromePasswordState();
}

class _ImportChromePasswordState extends State<ImportChromePassword>
    with StoragePerm {
  Logger log = getLogger('_ImportChromePasswordState');

  String msg = "";
  bool success = false;
  late MoveData moveData;
  late Data data;
  late Password password;
  late LifecycleState lifecycleState;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    moveData = Provider.of<MoveData>(context, listen: false);
    data = Provider.of<Data>(context, listen: false);
    password = Provider.of<Password>(context, listen: false);
    lifecycleState = Provider.of<LifecycleState>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text("Import chrome generated csv"),
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
                    text: 'Import password csv generrated by chrome browser',
                    style: Theme.of(context).textTheme.headline2,
                  ),
                ),
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
                  log.i('import_chrome_password.dart :: 24 :: key pressed');
                  lifecycleState.canLaunchPassword = false;
                  await getPermissions();
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles();
                  File? file;
                  if (result != null) {
                    file = File(result.files.single.path!);
                  }
                  setState(() {
                    msg = "WAITING";
                  });
                  lifecycleState.canLaunchPassword = true;
                  if (null != file) {
                    log.i(
                        'import_chrome_password.dart :: 33 :: path = ${file.path}');
                    String fileStr = file.readAsStringSync();
                    // log.i(
                    // 'import_chrome_password.dart :: 56 :: fileStr = $fileStr');

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
    // try {
    moveData.clearSelected();
    moveData.setCurrentItemId(1);
    Map csvData = Map();
    var result = await Navigator.pushNamed(context, '/move');
    if (null == result) {
      return Future<String>.value("No folder selected for import");
    } else {
      log.i('import_chrome_password.dart :: 116 :: Folder selectde = $result');
      log.i('import_chrome_password.dart :: 117 :: file= $fileStr');
      LineSplitter ls = LineSplitter();
      Map headers = Map();
      List<String> lines = ls.convert(fileStr); // fileStr.split("\n");
      log.i('import_chrome_password.dart :: 119 :: length = ${lines.length}');
      for (var i = 0; i < lines.length; i++) {
        String line = lines.elementAt(i);
        log.i('import_chrome_password.dart :: 123 :: line=$line');
        if (line.trim().length == 0) {
          continue;
        }
        List<String> columns = line.split(",");
        log.i(
            'import_chrome_password.dart :: 128 :: column length = ${columns.length}  ');
        if (i == 0) {
          for (var i = 0; i < columns.length; i++) {
            headers[i] = columns.elementAt(i);
          }
        } else {
          csvData[i] = Map();
          for (var j = 0; j < columns.length; j++) {
            csvData[i]["${headers[j]}"] = columns.elementAt(j);
          }
          log.i('import_chrome_password.dart :: 139 :: headers = $headers');
          log.i('import_chrome_password.dart :: 139 :: data = ${csvData[i]}');
          Item item = Item(isFolder: 0);
          item.name = csvData[i]["name"];
          item.parent = result as int;
          log.i('import_chrome_password.dart :: 142 :: item = $item');
          await data.addItem(item);

          ItemData itemData = ItemData();
          itemData.url = csvData[i]["url"];
          itemData.username = csvData[i]["username"];
          itemData.password = csvData[i]["password"];
          if (null != itemData.password && itemData.password!.length > 0) {
            itemData.password = PasswordCrypto.instance
                .encrypt(itemData.password!, password.passwordHash!);
          }
          itemData.itemId = item.id;
          log.i('import_chrome_password.dart :: 153 :: itemData=$itemData');
          await data.addItemData(itemData);
        }
      }
      log.i('import_chrome_password.dart :: 144 :: map = $csvData');
    }
    log.i('import_chrome_password.dart :: 95 :: result = $result');

    return Future<String>.value("SUCCESS");
    // } catch (e) {
    //   log.i('import_chrome_password.dart :: 73 :: $e');
    //   return Future<String>.value("Error while parsing the file data");
    // }
  }
}
