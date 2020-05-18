import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:password_tracker/services/database_util.dart';
import 'package:password_tracker/services/logging.dart';

class PasswordCrypto {
  final log = getLogger('PasswordCrypto');
  PasswordCrypto._privateConstructor();
  static final PasswordCrypto instance = PasswordCrypto._privateConstructor();

  Future<void> savePasssword(String password) async {
    log.i('45 : save password = $password');

    String passwordHash = hash(password);
    await TrackerDatabase.instance
        .insert('password', encrypt(passwordHash,passwordHash));
  }

  String hash(String str) {
    var bytes = utf8.encode(str);
    var digest = sha256.convert(bytes);
    List<int> l = List<int>(digest.bytes.length);
    log.i('crypto_util.dart :: 25 :: length = ${digest.bytes.length}');
    for (var i = 0; i < digest.bytes.length; i++) {
      l[i] = digest.bytes[i] & 0x7f;
    }
    String hashStr = Utf8Decoder().convert(l);
    return hashStr;
  }

  String encrypt(String str, String code) {
    log.i('30 : string=$str :: code = $code');
    if (str.trim().length == 0) {
      return "";
    }
    final key = Key.fromUtf8(code);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    String encryptedStr = encrypter.encrypt(str, iv: iv).base64;
    log.i('34 : encrypted string = $encryptedStr');
    return encryptedStr;
  }

  String decrypt(String str, String code) {
    log.i('43 : string=$str');
    if (str.trim().length == 0) {
      return "";
    }
    final key = Key.fromUtf8(code);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    Encrypted encrypted = Encrypted.fromBase64(str);
    String decryptedStr = encrypter.decrypt(encrypted, iv: iv);
    log.i('49 : decrypted string = $decryptedStr');
    return decryptedStr;
  }
}
