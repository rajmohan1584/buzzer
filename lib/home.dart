import 'dart:async';
import 'dart:io';

import 'package:buzzer/net/single_multicast.dart';
import 'package:buzzer/server/server.dart';
import 'package:buzzer/util/log.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';

import 'client/client.dart';
import 'model/command.dart';
import 'model/message.dart';

const testMode = false;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FocusNode focusNode = FocusNode();
  String mode = "idk"; // client, server
  bool isAndroid = Platform.isAndroid;

  final maxlen = 6;
  String passkey = "";
  final secretKey = "135246";

  bool anotherQuizMasterIsRunning = false;
  Timer? quizMasterCheckTimer;
  DateTime radarStartTime = DateTime.now();
  StreamSubscription<BuzzMsg>? _streamSubscription;
  bool allowServerLogin = false;
  bool allowClientLogin = false;

  String userName = ""; // TODO - Get it from cache.
  int userAvatar = -1; // Get it from cache.

  @override
  void initState() {
    startQuizMasterCheckTimer();
    resetAll();
    _streamSubscription =
        StaticSingleMultiCast.initialQueue.stream.listen(onServerMessage);
    super.initState();
  }

  @override
  dispose() {
    stopQuizMasterCheckTimer();
    super.dispose();
  }

  resetAll() {
    setState(() {
      passkey = "";
      mode = "idk";
      allowServerLogin = false;
      allowClientLogin = false;
      anotherQuizMasterIsRunning = false;
    });
  }

  /////////////////////////////////////////////////
  ///
  onServerMessage(BuzzMsg msg) {
    // Assert that there is no cross talk.
    assert(msg.source == BuzzCmd.server);
    assert(msg.cmd == BuzzCmd.hbq);

    setState(() {
      anotherQuizMasterIsRunning = true;
    });
  }

  startQuizMasterCheckTimer() {
    Log.log('Home - StartTimer');
    //stoptTimer();
    //const dur = Duration(seconds: 2);
    const dur = Duration(milliseconds: 500);
    quizMasterCheckTimer = Timer.periodic(dur, onQuizMasterCheckTimer);
  }

  final radarSpinSeconds = 3;
  Future getClientInfo() {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('Your Have the Right to Enter Your Name'),
                content: TextField(),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text("Let's Play"))
                ]));
  }

  onQuizMasterCheckTimer(_) async {
    // For a few seconds keep radar spinning
    Duration d = DateTime.now().difference(radarStartTime);

    if (d.inSeconds > radarSpinSeconds) {
      if (anotherQuizMasterIsRunning || isAndroid) {
        // Client Mode
        // Allow user to enter/change name and pick an avatar
        allowClientLogin = true;
        /*
        getClientInfo().then((value) {
          // Check if we found a QuizMaster.
          if (anotherQuizMasterIsRunning || isAndroid) {
            Log.log('Another Server is running, GoToClient in a sec');

            _streamSubscription?.cancel();
            _streamSubscription = null;
            stopQuizMasterCheckTimer();
            Future.delayed(const Duration(milliseconds: 1000), () {
              gotoClient();
            });
          }
        });
        */
      } else {
        // This user may be the server. Let him login
        setState(() {
          allowServerLogin = true;
        });
      }
    }
  }

  stopQuizMasterCheckTimer() {
    Log.log('Home - StopTimer');
    quizMasterCheckTimer?.cancel();
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
          Log.log('Login success. GoToServer in a sec');
          mode = "server";
          _streamSubscription?.cancel();
          _streamSubscription = null;
          Future.delayed(const Duration(milliseconds: 1000), () {
            gotoServer();
          });
        } else {
          // reset
          resetAll();
        }
      }
    });
  }

  onServerLogin() {
    if (testMode) {
      Log.log('Skip Login. GoToServer in a sec');
      _streamSubscription?.cancel();
      _streamSubscription = null;
      Future.delayed(const Duration(milliseconds: 1000), () {
        gotoServer();
      });
    }

    setState(() {
      mode = "server";
    });

    if (!testMode) {
      Future.delayed(const Duration(milliseconds: 100), () {
        // Do something
        FocusScope.of(context).requestFocus(focusNode);
      });
    }
  }

  onClientLogin() {}
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

  Widget messageOrInputs(w) {
    if (allowServerLogin) {
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
    } else if (allowClientLogin) {
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
      return SizedBox(height: 1);
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
          onPressed: onServerLogin, label: const Text("Login as Quiz Master"));
    } else if (allowClientLogin) {
      fab = FloatingActionButton.extended(
          onPressed: onClientLogin, label: const Text("Let's Play"));
    }

    final children = <Widget>[
      ...buildMessages(),
      ...buildInputs(w),
      buildSpinner(w)
    ];

    return Scaffold(
        appBar: AppBar(
            leading: WIDGETS.heartbeatIcon(anotherQuizMasterIsRunning),
            title: const Text("Buzzer - Searching...")),
        backgroundColor: Colors.black,
        floatingActionButton: fab,
        body: Column(children: children));
  }

  List<Widget> buildMessages() {
    final List<Widget> children = [];

    if (allowClientLogin) {
      children.add(Container(
          alignment: Alignment.topLeft,
          child:
              WIDGETS.assetImage("server-found.png", width: 350, height: 100)));
      children.add(Container(
          alignment: Alignment.topLeft,
          child: WIDGETS.assetImage("identify-yourself.png",
              width: 450, height: 150)));
    } else if (allowServerLogin) {
      children.add(Container(
          alignment: Alignment.topLeft,
          child: WIDGETS.assetImage("quizmaster-pin.png",
              width: 450, height: 150)));
    } else {
      children.add(Container(
          alignment: Alignment.topLeft,
          child: WIDGETS.assetImage("searching.png", width: 450, height: 150)));
    }
    children.add(
      const Divider(indent: 50, endIndent: 50, color: Color(0xff82fb4c)),
    );
    return children;
  }

  List<Widget> buildInputs(w) {
    final List<Widget> children = [];

    final borderRadius = BorderRadius.circular(15);
    final List<Widget> avatars = [];
    for (var i = 1; i <= 6; i++) {
      final color = userAvatar == i ? const Color(0xff82fb4c) : Colors.black;
      avatars.add(GestureDetector(
          onTap: () => setState(() {
                userAvatar = userAvatar == i ? -1 : i;
              }),
          child: Container(
              padding: const EdgeInsets.all(8),
              decoration:
                  BoxDecoration(color: color, borderRadius: borderRadius),
              child: ClipRect(
                child: SizedBox.fromSize(
                    size: const Size.fromRadius(50),
                    child:
                        Image.asset('assets/images/$i.png', fit: BoxFit.cover)),
              ))));
    }

    if (allowServerLogin) {
      children.add(SizedBox(
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
      ));
    } else if (allowClientLogin) {
      children.add(SizedBox(
          width: w / 2,
          height: 150,
          child: GridView.count(
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              crossAxisCount: 3,
              children: avatars)));

      children.add(SizedBox(
        width: w / 2,
        height: 50,
        child: TextField(
            focusNode: focusNode,
            autofocus: true,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.name,
            //onChanged: onClientNameChanged,
            style: const TextStyle(fontSize: 32, color: Color(0xff82fb4c))),
      ));
    } else {
      children.add(const SizedBox(height: 1));
    }

    return children;
  }

  buildSpinner(w) {
    if (allowClientLogin || allowServerLogin) {
      return const SizedBox(width: 1, height: 1);
    }
    return SizedBox(
        width: w * 2 / 3, height: w * 2 / 3, child: WIDGETS.buildRadar());
  }
  /*
    return Scaffold(
        appBar: AppBar(
            leading: WIDGETS.heartbeatIcon(anotherQuizMasterIsRunning),
            title: const Text("Buzzer - Searching...")),
        backgroundColor: Colors.black,
        floatingActionButton: fab,
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              alignment: Alignment.topRight,
              child: Text(
                "Text",
                style: TextStyle(color: Colors.white),
              )),
          messageOrInputs(w),
          const SizedBox(height: 20),
          SizedBox(
              width: w * 2 / 3, height: w * 2 / 3, child: WIDGETS.buildRadar())
        ])));
  }
  */
}
