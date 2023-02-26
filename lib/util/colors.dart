import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class COLORS {
  static get bid => Colors.blue;
  static get ask => Colors.red;

  static get up => Colors.green[200];
  static get down => Colors.red[200];

  static color(String scolor, [bool disabled = false]) {
    if (scolor == "primary") return CupertinoColors.systemBlue;
    if (scolor == "danger") return CupertinoColors.systemRed;

    if (scolor == "secondary") {
      if (disabled) return CupertinoColors.lightBackgroundGray;
      return CupertinoColors.systemGrey;
    }

    return CupertinoColors.systemPink;
  }

  static const Color logoColor1 = Color.fromRGBO(0xDA, 0x30, 0x45, 1.0);
  static const Color logoColor2 = Color.fromRGBO(0xFB, 0x7E, 0x21, 1.0);

  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);

  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey350 = Color(0xFFD6D6D6);

  static const Color yellow300 = Color(0xFFFFF176);

  static const Color green300 = Color(0xFFAED581);
  static const Color red200 = Color(0xFF424242);
  static const Color blue100 = Color(0xFF424242);

  static Map<String, Color> background = {
    'red': const Color.fromRGBO(255, 224, 230, 0.7),
    'green': const Color.fromRGBO(219, 242, 242, 1),
    //'green': const Color.fromRGBO(0xCB, 0xEA, 0xD2, 0.7),
    'orange': const Color.fromRGBO(255, 236, 217, 0.7),
    'yellow': const Color.fromRGBO(255, 245, 221, 0.7),
    'blue': const Color.fromRGBO(215, 236, 251, 0.7),
    'purple': const Color.fromRGBO(235, 224, 255, 0.7),
    'gray': const Color.fromRGBO(217, 219, 221, 0.7)
  };

  static Map<String, Color> darkBackground = {
    'red': const Color(0xffE74C3C),
    'green': const Color(0xff27AE60),
    'orange': const Color(0xffEB984E),
    'yellow': const Color(0xffF1C40F),
    'blue': const Color(0xff5DADE2),
    'purple': const Color(0xffA569BD),
    'gray': const Color(0xff95A5A6)
  };

  static Map<String, Color> border = {
    'red': const Color.fromRGBO(255, 138, 163, 1),
    'green': const Color.fromRGBO(119, 207, 207, 1),
    'orange': const Color.fromRGBO(255, 183, 111, 1),
    'yellow': const Color.fromRGBO(255, 205, 86, 1),
    'blue': const Color.fromRGBO(54, 162, 235, 1),
    'purple': const Color.fromRGBO(179, 140, 255, 1),
    'gray': const Color.fromRGBO(177, 181, 186, 1)
  };
}
