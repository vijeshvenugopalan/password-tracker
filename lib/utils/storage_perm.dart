import 'package:logger/logger.dart';
import 'package:password_tracker/services/logging.dart';
import 'package:permission_handler/permission_handler.dart';

class StoragePerm extends Object {
  Logger log = getLogger("StoragePerm");
    Future<void> getPermissions() async {
    log.i('storage_perm.dart :: 27 :: get permissions');
    final status = await Permission.storage.status;
    var request = true;
    if (status.isGranted) {
      request = false;
    }
    if (request) {
      final newStatus = await Permission.storage.request();
      log.i('storage_perm.dart :: 34 :: new status $newStatus');
    }
  }
}