import 'package:flutter/foundation.dart';

class Log {
  static log(Object s) {
    if (kDebugMode) {
      print(s);
    }
  }
}
