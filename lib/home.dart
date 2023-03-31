import 'package:buzzer/server/server.dart';
import 'package:buzzer/util/log.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FocusNode focusNode = FocusNode();
  bool qm = false;
  final maxlen = 6;
  String passkey = "";
  final secretKey = "135246";

  void gotoServer() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const BuzzServerScreen()));
  }

  onTextChanged(String s) {
    setState(() {
      passkey = s;
      if (passkey.length == maxlen) {
        if (passkey == secretKey) {
          // success - goto server
          gotoServer();
        } else {
          // reset
          passkey = "";
          qm = false;
        }
      }
    });
    Log.log(s);
  }

  onLogin() {
    setState(() {
      qm = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      // Do something
      FocusScope.of(context).requestFocus(focusNode);
    });
  }

  Widget passwordInput() {
    const green = Color(0xff82fb4c);
    final boxes = <Widget>[];
    for (var i = 0; i < maxlen; i++) {
      final len = passkey.length;
      Color? fillColor;
      if (i < len) fillColor = green;
      boxes.add(Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(
              color: green,
              blurRadius: 30,
            ),
          ],
        ),
      ));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: boxes,
    );
  }

  Widget messageOrInput(w) {
    if (qm) {
      return SizedBox(
        width: w / 2,
        height: 50,
        child: TextField(
            focusNode: focusNode,
            autofocus: true,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.number,
            onChanged: onTextChanged,
            style: const TextStyle(fontSize: 32, color: Color(0xff82fb4c))),
      );
    } else {
      return SizedBox(
          width: w,
          height: 50,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Text("Waiting For Quiz Master",
                style: TextStyle(fontSize: 32, color: Color(0xff82fb4c)))
          ]));
    }
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    if (w > MediaQuery.of(context).size.height) {
      w = MediaQuery.of(context).size.height;
    }
    w -= 20;

    Widget? fab;
    if (!qm) {
      fab = FloatingActionButton.extended(
          onPressed: onLogin, label: const Text("Login as Quiz Master"));
    }

    return Scaffold(
        appBar: AppBar(title: const Text("Buzzer - Waiting for Quiz Master")),
        backgroundColor: Colors.black,
        floatingActionButton: fab,
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          messageOrInput(w),
          SizedBox(height: 20),
          SizedBox(width: w, height: w, child: WIDGETS.buildRadar())
        ])));
  }
}
