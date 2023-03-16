import 'package:flutter/foundation.dart';

class Log {
  static log(Object s) {
    if (kDebugMode) {
      String context = StackTrace.current.toString();
      int startIndex = context.indexOf("#1") + 2;
      if (startIndex >= 0) {
        int endIndex = context.indexOf("#2", startIndex);
        if (endIndex >= 0) {
          context = context.substring(startIndex, endIndex);
        }
      }

      int cr = context.indexOf('\n');
      if (cr >= 0) {
        context = context.substring(0, cr - 1);
      }

      print("$s $context");
    }
  }
}
