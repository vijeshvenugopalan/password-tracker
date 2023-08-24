import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:password_tracker/state/password.dart';
import 'package:provider/provider.dart';

class Biometric extends StatefulWidget {
  @override
  _BiometricState createState() => _BiometricState();
}

class _BiometricState extends State<Biometric> {
  Logger log = getLogger('BiometricState');

  late Password password;

  @override
  Widget build(BuildContext context) {
    password = Provider.of<Password>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Biometric"),
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
            _getWidget(),
          ],
        ),
      ),
    );
  }

  Widget _getWidget() {
    if (password.isComplete) {
      if (password.availableBiometrics == null ||
          password.availableBiometrics!.length == 0) {
        return Center(
          child: Text("No Biometric capability available in this device"),
        );
      } else {
        return _getBiometricWidget(password.biometric == null);
      }
    } else {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Widget _getBiometricWidget(bool isEnable) {
    return Builder(
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              "Enable",
              style: Theme.of(context).textTheme.headline6,
            ),
            Switch(
              value: !isEnable,
              activeColor: Theme.of(context).toggleableActiveColor,
              onChanged: (value) async {
                bool canCheck = await password.canCheckBiometrics();
                log.i('biometric.dart :: 63 :: cancheck = $canCheck');
                log.i(
                    'biometric.dart :: 64 :: ${password.availableBiometrics!.length}');
                for (BiometricType biometric in password.availableBiometrics!) {
                  log.i('biometric.dart :: 66 :: type = $biometric');
                }

                log.i('biometric.dart :: 50 :: value changed $value');
                if (value) {
                  String result = await password.encrypt((status, text) async {
                    log.i(
                        'biometric.dart :: 84 :: status= $status :: text=$text');
                    if (status == 1) {
                      log.i('biometric.dart :: 87 set biometric');
                      await password.setBiometric(text);
                    }
                  });
                  log.i('biometric.dart :: 62 :: result=$result');
                  if (result != "SUCCESS") {
                    final snackBar = SnackBar(
                      content: Text("Error while enabling biometric $result"),
                      duration: Duration(seconds: 2),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                } else {
                  await password.setBiometric(null);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
