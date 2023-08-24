import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';
import 'package:password_tracker/services/crypto_util.dart';
import 'package:password_tracker/services/database_util.dart';
import 'package:password_tracker/services/logging.dart';

class Password extends ChangeNotifier {
  Logger log = getLogger('Password');

  static const String AUTH_CANCELLED = "AUTH-CANCELLED";
  static const String AUTH_ERROR = "AUTH-ERROR";
  static const String AUTH_FAILED = "AUTH-FAILED";

  String? _encryptedPassword = "";
  String? _encryptedBiometric = "";
  String? passwordHash = null;
  bool _isComplete = false;
  List<BiometricType>? availableBiometrics;
  Function callback = () => {};
  bool initalSetup = true;

  static const platform = const MethodChannel('vijesh.flutter.dev/fingerprint');

  Password() {
    _getPasswordState();
    platform.setMethodCallHandler(_handleMethod);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case "successCallback":
        log.i('main.dart :: 62 :: ${call.arguments}');
        callback(1, call.arguments);
        return new Future.value("");
      case "failureCallback":
        log.i('password.dart :: 32 :: failure callback = ${call.arguments}');
        callback(0, call.arguments);
        return new Future.value("");
    }
  }

  Future<String> encrypt(Function callback) async {
    this.callback = callback;
    try {
      await platform.invokeMethod('encrypt', {"text": passwordHash});
    } on PlatformException catch (e) {
      log.i('password.dart :: 51 :: ${e.toString()}');
      setBiometric(null);
      return Future.value(e.message);
    } on Exception catch (ex) {
      log.i('password.dart :: 52 :: error = ${ex.toString()}');
      setBiometric(null);
      return Future.value(
          ". Please define fingerprint through device settings.");
    }
    return Future.value("SUCCESS");
  }

  Future<String> decrypt(Function callback) async {
    this.callback = callback;
    try {
      await platform.invokeMethod('decrypt', {"text": _encryptedBiometric});
    } on PlatformException catch (e) {
      log.i('password.dart :: 67 :: ${e.toString()}');
      setBiometric(null);
      return Future.value(e.message);
    } on Exception catch (ex) {
      log.i('password.dart :: 66 :: error = ${ex.toString()}');
      setBiometric(null);
      return Future.value(
          ". Please define fingerprint through device settings.");
    }
    return Future.value("SUCCESS");
  }

  void _getPasswordState() async {
    _encryptedPassword = await TrackerDatabase.instance.getValue('password');
    _encryptedBiometric = await TrackerDatabase.instance.getValue('biometric');
    var localAuth = LocalAuthentication();
    availableBiometrics = await localAuth.getAvailableBiometrics();
    _isComplete = true;
    log.i('22 : password=$_encryptedPassword');
    notifyListeners();
  }

  Future<bool> canCheckBiometrics() async {
    var localAuth = LocalAuthentication();
    bool ret = await localAuth.canCheckBiometrics;
    return Future.value(ret);
  }

  String? get password {
    return _encryptedPassword;
  }

  Future<void> savePasssword(String password) async {
    log.i('45 : save password = $password');

    String passwordHash = PasswordCrypto.instance.hash(password);
    String encryptedPassword =
        PasswordCrypto.instance.encrypt(passwordHash, passwordHash);
    _encryptedPassword = encryptedPassword;
    await TrackerDatabase.instance.insert('password', encryptedPassword);
  }

  String? get biometric {
    return (_encryptedBiometric != null) ? _encryptedBiometric : null;
  }

  Future<void> setBiometric(String? biometric) async {
    log.i("password.dart ::113 :: biometric=$biometric");
    _encryptedBiometric = biometric;
    await TrackerDatabase.instance.insert('biometric', biometric);
    notifyListeners();
  }

  bool get isComplete {
    return _isComplete;
  }
}
