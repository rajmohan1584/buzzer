import 'package:buzzer/util/command.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WIDGETS {
  static Image assetImage(String file,
      {double width = 30, double height = 30, color}) {
    return Image.asset('assets/images/$file',
        width: width, height: height, color: color);
  }

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

  static Widget redBuzzer0() {
    final img = assetImage("buzzer.png", width: 240, height: 240);
    const rad = 105.0;
    return CircleAvatar(
        radius: rad,
        backgroundColor: Colors.grey,
        child: CircleAvatar(
            radius: rad - 3,
            backgroundColor: Colors.black,
            child: ClipOval(child: img)));
  }

  static Widget redBuzzer(onPressed) {
    final img = assetImage("buzzer.png", width: 240, height: 240);
    return IconButton(
      icon: img,
      iconSize: 150,
      onPressed: onPressed,
    );
  }

  static Widget redBuzzerIcon(bool buzzed) {
    final img = assetImage("buzzer.png", width: 40, height: 40);
    return IconButton(
      icon: img,
      iconSize: 50,
      onPressed: null,
    );
  }

  static Widget yesBuzzer(onPressed) {
    final img = assetImage("buzzer-yes.png", width: 240, height: 240);
    return IconButton(
      icon: img,
      iconSize: 150,
      onPressed: onPressed,
    );
  }

  static Widget noBuzzer(onPressed) {
    final img = assetImage("buzzer-no.png", width: 240, height: 240);
    return IconButton(
      icon: img,
      iconSize: 150,
      onPressed: onPressed,
    );
  }

  static Widget buzzedStateIcon(String buzzedState) {
    String png = "buzzer-null.png";
    if (buzzedState == BuzzCmd.buzzYes) png = "buzzer-yes.png";
    if (buzzedState == BuzzCmd.buzzNo) png = "buzzer-no.png";
    final img = assetImage(png, width: 40, height: 40);
    return IconButton(
      icon: img,
      iconSize: 50,
      onPressed: null,
    );
  }

  static Widget plusIconButton(onPressed) {
    return IconButton(
      icon: const Icon(CupertinoIcons.add_circled),
      iconSize: 25,
      onPressed: onPressed,
    );
  }

  static Widget minusIconButton(onPressed) {
    return IconButton(
      icon: const Icon(CupertinoIcons.minus_circled),
      iconSize: 25,
      onPressed: onPressed,
    );
  }

  static Widget buzzedStatus(String buzzedState, int index) {
    Color textColor = Colors.black;
    if (buzzedState.isEmpty) {
      textColor = Colors.white;
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.grey,
          border: Border.all(color: Colors.black, width: 3),
          shape: BoxShape.circle,
        ),
        height: 38.0,
        width: 38.0,
        child: Center(
            child: Text('$index',
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold))),
      ),
      buzzedStateIcon(buzzedState)
    ]);
  }
}
