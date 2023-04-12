import 'package:buzzer/model/command.dart';
import 'package:buzzer/model/constants.dart';
import 'package:buzzer/util/format.dart';
import 'package:buzzer/util/heartbeat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shake_animated/flutter_shake_animated.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';

import '../widgets/int_spinner.dart';

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

  static Widget nameText(String name, {fontSize = 14.0}) {
    return Text(name, style: TextStyle(fontSize: fontSize));
  }

  static Widget valueText(String value, {fontSize = 14.0}) {
    return Text(value, style: TextStyle(fontSize: fontSize));
  }

  static Widget keyValueText(String value) {
    return Text(value,
        style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w700));
  }

  static Widget nameValue(String name, String value, {fontSize = 20.0}) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          valueText(value, fontSize: fontSize),
          const SizedBox(height: 5),
          nameText(name)
        ]);
  }

  static Widget nameWidget(String name, Widget value, {fontSize = 20.0}) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          value,
          const SizedBox(height: 5),
          nameText(name, fontSize: fontSize)
        ]);
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

  static Widget redBuzzer(Function() onPressed) {
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

  static Widget tamilText(String text, double fontSize,
      {Color color = Colors.white}) {
    return Text(text,
        style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            fontFamily: "Catamaran-VariableFont_wght",
            color: color));
  }

  static Widget appBarTitle({String name = ""}) {
    return Text("தெரியுமா?  ${CONST.appVersion}  $name",
        style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            fontFamily: "Catamaran-VariableFont_wght",
            color: Colors.white));
  }

  static Widget yesBuzzerTitle() {
    return const Text("தெரியும்",
        style: TextStyle(
            fontSize: 30, fontFamily: "Coiny-Regular", color: Colors.black));
  }

  static Widget noBuzzerTitle() {
    return const Text("தெரியாது",
        style: TextStyle(
            fontSize: 18, fontFamily: "Coiny-Regular", color: Colors.white));
  }

  static Widget waitingForClients() {
    return const Text("Waiting for Students to Join!",
        style: TextStyle(fontSize: 20));
  }

  static Widget heartbeatIcon(bool alive) {
    if (alive) {
      return HeartBeat(
          child: const Icon(
        CupertinoIcons.heart_fill,
        color: Colors.red,
      ));
    }
    return const Icon(CupertinoIcons.heart_slash);
  }

  static Widget buildBuzzer(Widget img, Widget text) {
    return Center(
        child: Stack(
      children: <Widget>[
        Container(
          alignment: Alignment.center,
          child: img,
        ),
        Container(alignment: Alignment.center, child: text),
      ],
    ));
  }

  static Widget yesBuzzer(Function() onPressed) {
    final img = assetImage("green-empty.webp", width: 240, height: 240);
    return IconButton(
      icon: buildBuzzer(img, yesBuzzerTitle()),
      iconSize: 200,
      onPressed: onPressed,
    );
  }

  static Widget noBuzzer(Function() onPressed) {
    final img = assetImage("red-empty.webp", width: 240, height: 240);
    return IconButton(
      icon: buildBuzzer(img, noBuzzerTitle()),
      iconSize: 150,
      onPressed: onPressed,
    );
  }

  static Widget buzzedStateIcon(String buzzedState) {
    String png = "buzzer-null.png";
    if (buzzedState == BuzzCmd.buzzYes) png = "buzzer-yes.png";
    if (buzzedState == BuzzCmd.buzzNo) png = "buzzer-no.png";
    return assetImage(png, width: 40, height: 40);
  }

  static Widget plusIconButton(Function() onPressed) {
    return IconButton(
      icon: const Icon(CupertinoIcons.add_circled),
      iconSize: 25,
      onPressed: onPressed,
    );
  }

  static Widget minusIconButton(Function() onPressed) {
    return IconButton(
      icon: const Icon(CupertinoIcons.minus_circled),
      iconSize: 25,
      onPressed: onPressed,
    );
  }

  static Widget segueIconButton(Function() onPressed) {
    return IconButton(
      icon: const Icon(CupertinoIcons.right_chevron),
      iconSize: 25,
      onPressed: onPressed,
    );
  }

  static Widget popupWindowIconButton(Function() onPressed) {
    return IconButton(
      icon: const Icon(CupertinoIcons.arrowshape_turn_up_right),
      iconSize: 25,
      onPressed: onPressed,
    );
  }

  static Widget bellIconButton(Function() onPressed,
      {bool hShake = false, bool vShake = false}) {
    Widget w = IconButton(
      icon: const Icon(CupertinoIcons.bell_circle),
      iconSize: 25,
      onPressed: onPressed,
    );

    if (!hShake && !vShake) return w;

    ShakeConstant shakeConstant =
        hShake ? ShakeHorizontalConstant2() : ShakeVerticalConstant1();
    return ShakeWidget(
        shakeConstant: shakeConstant,
        autoPlay: true,
        enableWebMouseHover: false,
        child: w);
  }

  static Widget buzzedStatus(String buzzedState, Duration? buzzedYesDelta) {
    final value = buzzedStateIcon(buzzedState);
    if (buzzedYesDelta == null) {
      return value;
    }

    String disp = FMT.buzzedDelta(buzzedYesDelta);

    return nameWidget(disp, value, fontSize: 14.0);
    /*
    Color textColor = Colors.black;
    if (buzzedState.isEmpty) {
      textColor = Colors.white;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
  */
  }

  static Widget button(String buttonText, Function() onPressed) {
    return ElevatedButton(onPressed: onPressed, child: Text(buttonText));
  }

  static Widget clientButton(Function() onPressed) {
    return ElevatedButton(onPressed: onPressed, child: tamilText("மாணவர்", 20));
  }

  static Widget serverButton(Function() onPressed) {
    return ElevatedButton(onPressed: onPressed, child: tamilText("நடுவர்", 20));
  }

  static Widget buttonAndDesc(
      String buttonText, Function() onPressed, String descText) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(onPressed: onPressed, child: Text(buttonText)),
          const SizedBox(width: 10),
          Text(descText)
        ]);
  }

  static Widget switchRowWithInput(
      String text,
      bool switchValue,
      void Function(bool) onSwitchChanged,
      int inputValue,
      void Function(int) onInputChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
            flex: 1,
            child: Transform.scale(
                scale: 0.75,
                child: CupertinoSwitch(
                    value: switchValue, onChanged: onSwitchChanged))),
        Expanded(flex: 3, child: Text(text)),
        Expanded(flex: 2, child: IntSpinner(inputValue, 1, 60, onInputChanged)),
      ],
    );
  }

  static Widget switchRowWithInput0(
      String text,
      bool switchValue,
      void Function(bool) onSwitchChanged,
      double inputValue,
      void Function(double) onInputChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(text),
        const SizedBox(width: 10),
        CupertinoSwitch(value: switchValue, onChanged: onSwitchChanged),
        const SizedBox(width: 10),
        SizedBox(
          width: 150,
          height: 50,
          child: CupertinoSpinBox(
            min: 1,
            max: 60,
            value: inputValue,
            direction: Axis.horizontal,
            onChanged: onInputChanged,
          ),
        )
      ],
    );
  }

  static Widget buildCountdownTime(int sec) {
    final Color color = sec > 5 ? Colors.black : Colors.red;
    return Text(
      FMT.sec(sec.toDouble()),
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: color),
    );
  }

  static Widget buildRadar() {
    return Image.asset(
      "assets/images/radar.gif",
      height: 125.0,
      width: 125.0,
    );
  }
}
