import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/state/data.dart';
import 'package:password_tracker/state/lifecycle_state.dart';
import 'package:password_tracker/utils/storage_perm.dart';
import 'package:path_provider/path_provider.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class ExportFile extends StatefulWidget {
  @override
  _ExportFileState createState() => _ExportFileState();
}

class _ExportFileState extends State<ExportFile> with StoragePerm {
  Logger log = getLogger("ExportFileState");

  Directory externalDirectory;
  Directory pickedDirectory;
  Data data;

  Future<void> getStorage() async {
    log.i('export_file.dart :: 45 :: get storage');
    final directory = await getExternalStorageDirectory();
    setState(() => externalDirectory = directory);
  }

  Future<void> init() async {
    await getPermissions();
    await getStorage();
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    data = Provider.of<Data>(context, listen: false);

    if (null != externalDirectory) {
      log.i('export_file.dart :: 58 :: ${externalDirectory.parent.absolute}');
      log.i(
          'export_file.dart :: 59 :: ${externalDirectory.parent.parent.parent.parent.parent.parent.parent.parent.parent.absolute}');
    } else {
      log.i('export_file.dart :: 60 :: externa directory is null');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Export to File"),
      ),
      body: (externalDirectory != null && data.isComplete)
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                if (details.delta.dx > 10) {
                  Navigator.pop(context);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          text: 'What happens when you click the share button:',
                          style: Theme.of(context).textTheme.display2,
                          children: <TextSpan>[
                            TextSpan(
                              text: '\n- File gets created at location: ',
                              style: Theme.of(context).textTheme.display3,
                            ),
                            TextSpan(
                              text: '\n${externalDirectory.path}/passwords.txt',
                              style: Theme.of(context).textTheme.display4,
                            ),
                            TextSpan(
                              text:
                                  '\n- Share option will popup with the file as source',
                              style: Theme.of(context).textTheme.display3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Center(
                    child: ButtonTheme(
                      minWidth: 300,
                      child: RaisedButton(
                        child: Text(
                          "Share",
                          style: TextStyle(
                            fontSize:
                                Theme.of(context).textTheme.display1.fontSize,
                          ),
                        ),
                        color: Theme.of(context)
                            .buttonTheme
                            .colorScheme
                            .background,
                        textColor:
                            Theme.of(context).buttonTheme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onPressed: () async {
                          log.i('export_file.dart :: 77 :: on pressed ');
                          await _writeAndShare();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const CircularProgressIndicator(),
    );
  }

  Future<void> _writeAndShare() async {
    log.i(
        'export_file.dart :: 128 :: external path = ${externalDirectory.path}');
    File file = File('${externalDirectory.path}/passwords.txt');
    log.i('export_file.dart :: 129 :: path = ${file.path}');
    String jsonStr = json.encode(data.data);
    // log.i('export_file.dart :: 130 :: json string = $jsonStr');
    if (!file.existsSync()) {
      file.createSync();
    }
    file.writeAsStringSync(jsonStr);
    log.i('export_file.dart :: 132 :: File write complete');
    log.i('export_file.dart :: 139 :: Going to share file');
    await FlutterShare.shareFile(
      title: 'Passwords',
      text: 'Passwords',
      filePath: file.path,
    );
  }
}
