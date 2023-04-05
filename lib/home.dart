import 'dart:async';

import 'package:buzzer/server/server.dart';
import 'package:buzzer/util/log.dart';
import 'package:buzzer/util/multicast.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';

import 'client/client.dart';

class Home extends StatefulWidget {
  Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FocusNode focusNode = FocusNode();
  String mode = "idk"; // client, server
  bool allowServerLogin = false;
  final maxlen = 6;
  String passkey = "";
  final secretKey = "135246";
  bool alive = false;
  Timer? timer;
  int timerCounter = 0;

  @override
  void initState() {
    MulticastListenerNew.init();
    startTimer();
    super.initState();
    resetAll();
  }

  @override
  dispose() {
    stoptTimer();
    super.dispose();
  }

  resetAll() {
    setState(() {
      passkey = "";
      mode = "idk";
      allowServerLogin = false;
      timerCounter = 0;
    });
  }

  startTimer() {
    Log.log('Home - StartTimer');
    stoptTimer();
    const dur = Duration(seconds: 5);
    timer = Timer.periodic(dur, onTimer);
  }

  onTimer(_) async {
    final serverIp = MulticastListenerNew.serverData;
    Log.log('Home - OnTimer serverIp:$serverIp');

    setState(() {
      timerCounter++;
      if (serverIp.isNotEmpty) {
        alive = true;
      }
    });

    // For 10 seconds keep radar spinning
    if (timerCounter > 2) {
      // Check if we found a QuizMaster.
      if (serverIp.isNotEmpty) {
        stoptTimer();
        onFoundQuizMaster(serverIp);
      }
      if (serverIp.isEmpty) {
        // This user may be the server. Let him login
        setState(() {
          allowServerLogin = true;
        });
      }
    }
  }

  stoptTimer() {
    Log.log('Home - StopTimer');
    timer?.cancel();
  }

  void onFoundQuizMaster(String ip) {
    Log.log("onFoundQuizMaster IP: $ip");
    setState(() {
      mode = "client";
      Future.delayed(const Duration(milliseconds: 1000), () {
        gotoClient();
      });
    });
  }

  void gotoClient() {
    // Leave the multicast listner on.
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const BuzzClientScreen()));
  }

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
          mode = "server";
          MulticastListenerNew.exit();
          Future.delayed(const Duration(milliseconds: 1000), () {
            gotoServer();
          });
        } else {
          // reset
          resetAll();
        }
      }
    });
    Log.log(s);
  }

  onLogin() {
    setState(() {
      mode = "server";
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
    if (mode == "server") {
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
            Text("Searching For Quiz Master...",
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
    w -= 50;

    Widget? fab;
    if (allowServerLogin && mode == "idk") {
      fab = FloatingActionButton.extended(
          onPressed: onLogin, label: const Text("Login as Quiz Master"));
    }

    return Scaffold(
        appBar: AppBar(
            leading: WIDGETS.heartbeatIcon(alive),
            title: const Text("Buzzer - Searching...")),
        backgroundColor: Colors.black,
        floatingActionButton: fab,
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          messageOrInput(w),
          const SizedBox(height: 20),
          SizedBox(
              width: w * 2 / 3, height: w * 2 / 3, child: WIDGETS.buildRadar())
        ])));
  }
}
