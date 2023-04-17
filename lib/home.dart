import 'dart:async';
import 'dart:io';

import 'package:buzzer/client/avatar_selector.dart';
import 'package:buzzer/client/client_name_input.dart';
import 'package:buzzer/model/constants.dart';
import 'package:buzzer/model/game_cache.dart';
import 'package:buzzer/net/single_multicast.dart';
import 'package:buzzer/server/server.dart';
import 'package:buzzer/util/language.dart';
import 'package:buzzer/util/log.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';

import 'client/client.dart';
import 'model/defs.dart';
import 'model/message.dart';

const testMode = false;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FocusNode focusNode = FocusNode();
  bool isAndroid = Platform.isAndroid;

  final maxlen = 6;
  String passkey = "";
  final secretKey = "135246";

  bool anotherQuizMasterIsRunning = false;
  Timer? quizMasterCheckTimer;
  DateTime radarStartTime = DateTime.now();
  StreamSubscription<BuzzMsg>? _streamSubscription;

  bool showServerLogin = false;
  bool allowServerLogin = false;
  bool allowClientLogin = false;

  // Get it from cache later
  late String userId;
  late StringUtf8 userNameUtf8;
  late String userName;
  late int userAvatar;

  final passKeyController = TextEditingController();
  final userNameController = TextEditingController();

  @override
  void initState() {
    passkey = "";
    showServerLogin = false;
    allowServerLogin = false;
    allowClientLogin = false;
    anotherQuizMasterIsRunning = false;

    startQuizMasterCheckTimer();

    _streamSubscription =
        StaticSingleMultiCast.initialQueue.stream.listen(onServerMessage);

    // Get it from cache later
    BuzzMap? savedUser = GameCache.getSavedClientFromCache();
    userId = savedUser?[BuzzDef.id] ?? "";
    userAvatar = savedUser?[BuzzDef.avatar] ?? 0;

    userName = savedUser?[BuzzDef.name] ?? "";
    userNameUtf8 = LANG.parseNameUtf8(savedUser);
    if (userNameUtf8.isNotEmpty) userName = LANG.socket2Name(userNameUtf8);

    userNameController.text = userName;
    super.initState();
  }

  @override
  dispose() {
    stopQuizMasterCheckTimer();
    super.dispose();
  }

  /////////////////////////////////////////////////
  ///
  onServerMessage(BuzzMsg msg) {
    // Assert that there is no cross talk.
    assert(msg.source == BuzzDef.server);
    assert(msg.cmd == BuzzDef.hbq);

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
      } else {
        // This user may be the server. Show the server login button
        setState(() {
          showServerLogin = true;
        });
      }
    }
  }

  stopQuizMasterCheckTimer() {
    Log.log('Home - StopTimer');
    quizMasterCheckTimer?.cancel();
  }

  void gotoClient() {
    // House keeping.
    _streamSubscription?.cancel();
    _streamSubscription = null;
    stopQuizMasterCheckTimer();

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) =>
                BuzzClientScreen(userId, userName, userAvatar)));
  }

  void gotoServer() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const BuzzServerScreen()));
  }

  onPassKeyTextChanged(String s) {
    setState(() {
      passkey = s;
    });

    if (passkey.length == maxlen) {
      if (passkey == secretKey) {
        // success - goto server
        Log.log('Login success. GoToServer in a sec');
        _streamSubscription?.cancel();
        _streamSubscription = null;
        Future.delayed(const Duration(milliseconds: 1000), () {
          gotoServer();
        });
      } else {
        // reset
        //resetAll();
        // TODO - shakey shakey for wrong password
        setState(() {
          passKeyController.text = "";
        });
      }
    }
  }

  onClientNameChanged(String name) {
    setState(() {
      userName = name;
    });
  }

  onClickServerLogin() {
    if (testMode) {
      Log.log('Skip Login. GoToServer in a sec');
      _streamSubscription?.cancel();
      _streamSubscription = null;
      Future.delayed(const Duration(milliseconds: 1000), () {
        gotoServer();
      });
    }

    setState(() {
      allowServerLogin = true;
    });

    if (!testMode) {
      // This is to automatically popup the keybord on phones.
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(focusNode);
      });
    }
  }

  /*
  Widget passwordInput() {
    final green = CONST.textColor;
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
          boxShadow: [
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
            style: TextStyle(fontSize: 32, color: CONST.textColor)),
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
            style: TextStyle(fontSize: 32, color: CONST.textColor)),
      );
    } else {
      return const SizedBox(height: 1);
    }
  }
  */

  onUserAvatarChanged(int avatar) {
    setState(() => userAvatar = avatar);
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    if (w > MediaQuery.of(context).size.height) {
      w = MediaQuery.of(context).size.height;
    }
    w -= 50;

    Widget? fab;
    if (showServerLogin && !allowClientLogin) {
      fab = FloatingActionButton.extended(
          onPressed: onClickServerLogin,
          label: const Text("Login as Quiz Master"));
    } else if (allowClientLogin) {
      fab = FloatingActionButton.extended(
          onPressed: gotoClient, label: const Text("Let's Play தெரியுமா"));
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
              width: 550, height: 150)));
    } else {
      children.add(Container(
          alignment: Alignment.topLeft,
          child: WIDGETS.assetImage("searching.png", width: 450, height: 150)));
    }
    children.add(
      Divider(indent: 50, endIndent: 50, color: CONST.textColor),
    );
    children.add(const SizedBox(height: 10));

    return children;
  }

  List<Widget> buildInputs(w) {
    final List<Widget> children = [];

    if (allowServerLogin) {
      children.add(SizedBox(
        width: w / 2,
        height: 50,
        child: TextField(
            textAlign: TextAlign.center,
            maxLength: secretKey.length,
            focusNode: focusNode,
            autofocus: true,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.number,
            controller: passKeyController,
            onChanged: onPassKeyTextChanged,
            style: TextStyle(fontSize: 32, color: CONST.textColor)),
      ));
    } else if (allowClientLogin) {
      children.add(UserAvatarSelector(userAvatar, onUserAvatarChanged, w));

      children.add(UserNameInput(userName, userNameController, w));
      /*
      children.add(SizedBox(
        width: w / 1.5,
        height: 50,
        child: TextField(
            textAlign: TextAlign.center,
            maxLength: 25,
            decoration: const InputDecoration(
                hintText: "உ ன்   பெ ய ர்",
                hintStyle: TextStyle(color: Colors.blueGrey)),
            focusNode: focusNode,
            autofocus: true,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.name,
            controller: userNameController,
            onChanged: onClientNameChanged,
            style: TextStyle(fontSize: 32, color: CONST.textColor)),
      ));
      */
    } else {
      children.add(const SizedBox(height: 1));
    }

    return children;
  }

  buildSpinner(w) {
    if (allowClientLogin) {
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
