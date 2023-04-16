import 'dart:convert' show utf8;

import 'package:buzzer/model/defs.dart';

class LANG {
  static final RegExp _tamilPattern = RegExp(r'[\u0B80-\u0BFF]');
  static bool isTamil(String input) {
    // TODO - send language test in socket message
    return false;
//    return _tamilPattern.hasMatch(input);
  }

  static List<int> name2Socket(String name) {
    return utf8.encode(name);
  }

  static String socket2Name(List<int> sName) {
    return utf8.decode(sName);
  }

  static StringUtf8 parseNameUtf8(BuzzMap? map) {
    if (map != null) {
      if (map[BuzzDef.nameUtf8] != null) {
        return map[BuzzDef.nameUtf8].cast<int>();
      }
    }
    return [];
  }
}
