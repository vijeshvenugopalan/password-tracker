import 'package:flutter/foundation.dart';

class LifecycleState extends ChangeNotifier {
  static int active = 1;
  static int paused = 2;
  static int resumed = 3;
  // static int inactive = 4;

  int _state = active;
  bool canLaunchPassword = false;

  // set canLaunchPassword (bool canLaunch) {
  //   _canLaunchPassword = canLaunch;
  //   notifyListeners();
  // }

  // bool get canLaunchPassword {
  //   return _canLaunchPassword;
  // }

  set state (int s) {
    _state = s;
    notifyListeners();
  }

  int get state {
    return _state;
  }
}