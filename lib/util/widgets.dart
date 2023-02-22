import 'package:flutter/material.dart';

class WIDGETS {
  static Widget joinButton(Function() onPressed) {
    return ElevatedButton(onPressed: onPressed, child: const Text("JOIN"));
  }

  static Widget createServerButton(Function() onPressed) {
    return ElevatedButton(onPressed: onPressed, child: const Text("CREATE"));
  }

  static Widget nameText(String name) {
    return Text(name, style: const TextStyle(fontSize: 12.0));
  }

  static Widget valueText(String value) {
    return Text(value, style: const TextStyle(fontSize: 14.0));
  }

  static Widget keyValueText(String value) {
    return Text(value,
        style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w700));
  }

  static Widget nameValue(String name, String value) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [valueText(value), nameText(name)]);
  }
}
