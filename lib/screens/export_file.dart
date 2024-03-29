import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/state/data.dart';
import 'package:password_tracker/utils/storage_perm.dart';
import 'package:path_provider/path_provider.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:provider/provider.dart';

class ExportFile extends StatefulWidget {
  @override
  _ExportFileState createState() => _ExportFileState();
}

class _ExportFileState extends State<ExportFile> with StoragePerm {
  Logger log = getLogger("ExportFileState");

  Directory? externalDirectory;
  late Directory pickedDirectory;
  late Data data;

  Future<void> getStorage() async {
    log.i('export_file.dart :: 45 :: get storage');
    var directory = await getExternalStorageDirectory();
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
      log.i('export_file.dart :: 58 :: ${externalDirectory?.parent.absolute}');
      log.i(
          'export_file.dart :: 59 :: ${externalDirectory?.parent.parent.parent.parent.parent.parent.parent.parent.parent.absolute}');
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
                          style: Theme.of(context).textTheme.headline3,
                          children: <TextSpan>[
                            TextSpan(
                              text: '\n- File gets created at location: ',
                              style: Theme.of(context).textTheme.headline2,
                            ),
                            TextSpan(
                              text:
                                  '\n${externalDirectory?.path}/passwords.txt',
                              style: Theme.of(context).textTheme.headline1,
                            ),
                            TextSpan(
                              text:
                                  '\n- Share option will popup with the file as source',
                              style: Theme.of(context).textTheme.headline2,
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
                      child: ElevatedButton(
                        child: Text(
                          "Share",
                          style: TextStyle(
                            fontSize:
                                Theme.of(context).textTheme.headline4!.fontSize,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .buttonTheme
                              .colorScheme!
                              .background,
                          foregroundColor: Theme.of(context)
                              .buttonTheme
                              .colorScheme!
                              .primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () async {
                          log.i('export_file.dart :: 77 :: on pressed ');
                          await _writeAndShare(context);
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

  Future<void> _writeAndShare(BuildContext context) async {
    log.i(
        'export_file.dart :: 128 :: external path = ${externalDirectory?.path}');
    File file = File('${externalDirectory?.path}/passwords.txt');
    log.i('export_file.dart :: 129 :: path = ${file.path}');
    String jsonStr = json.encode(data.data);
    // log.i('export_file.dart :: 130 :: json string = $jsonStr');
    if (!file.existsSync()) {
      file.createSync();
    }
    file.writeAsStringSync(jsonStr);
    log.i('export_file.dart :: 132 :: File write complete');
    log.i('export_file.dart :: 139 :: Going to share file');
    // await FlutterShare.shareFile(
    //   title: 'Passwords',
    //   text: 'Passwords',
    //   filePath: file.path,
    // );
    // ShareExtend.share(file.path, 'password.txt');
    final box = context.findRenderObject() as RenderBox?;
    final files = <XFile>[];
    files.add(XFile(file.path, name: "passwords"));
    await Share.shareXFiles(files,
        text: "passwords",
        subject: "passwords",
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
  }
}
