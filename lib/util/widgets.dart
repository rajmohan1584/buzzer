import 'package:flutter/material.dart';

class WIDGETS {
  static Widget joinButton(Function() onPressed) {
    return ElevatedButton(onPressed: onPressed, child: const Text("JOIN"));
  }

  static Widget createServerButton(Function() onPressed) {
    return ElevatedButton(onPressed: onPressed, child: const Text("CREATE"));
  }
}
