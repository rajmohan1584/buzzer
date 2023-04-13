import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:buzzer/net/server_direct.dart';
import 'package:buzzer/widgets/top_buzzers.dart';
import 'package:flutter/material.dart';
import 'package:buzzer/util/buzz_state.dart';
import 'package:buzzer/util/log.dart';
import 'package:buzzer/model/message.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:nanoid/async.dart';

import '../model/command.dart';
import '../net/single_multicast.dart';

const bool bellAudioEnabled = false;

class BuzzClientScreen extends StatefulWidget {
  const BuzzClientScreen({super.key});

  @override
  State<BuzzClientScreen> createState() => _BuzzClientScreenState();
}

class _BuzzClientScreenState extends State<BuzzClientScreen>
    with SingleTickerProviderStateMixin {
  String id = "";
  BuzzState state = BuzzState.clientWaitingForServer;
  bool connected = false;
  final userController = TextEditingController();
  String userName = "";
  int myScore = 0;
  List<BuzzMsg> serverMessages = [];
  final audioPlayer = AudioPlayer();
  String error = "";
  int secondsRemaining = 0;
  bool bellRinging = false;
  bool bellFlashing = false;
  Timer? heartbeatCheckTimer;
  DateTime lastHeartbeatTime = DateTime.now();
  bool alive = false;
  Map? topBuzzers;

  @override
  void initState() {
    Log.log('Client InitState');
    userController.text = "Raj";
    startHeartbeatCheckTimer();

    StaticSingleMultiCast.mainQueue.stream.listen((BuzzMsg msg) {
      onServerMessage(msg);
    });
    ServerDirect.androidInQueue.stream.listen((BuzzMsg msg) {
      onServerMessage(msg);
    });

    registerUs();

    super.initState();
  }

  @override
  void dispose() {
    userController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      leading: WIDGETS.heartbeatIcon(alive),
      title: WIDGETS.appBarTitle(name: ""),
    );

    return WillPopScope(
        onWillPop: () async {
          // socket.close();
          return true;
        },
        child: Scaffold(appBar: appBar, body: buildBody()));
  }

  Widget buildBody() {
    final List<Widget> children = buildPlayArea();

    return Column(
        children: [
      buildMyself(),
      const Divider(height: 2),
      const SizedBox(height: 30),
      ...children
    ]);
  }

  Widget buildMyself() {
    final name = Text(userName,
        style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold));
    Widget row = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          name,
          WIDGETS.nameValue("SCORE", "$myScore", fontSize: 30.0),
          WIDGETS.bellIconButton(() => sendPingToServer(),
              hShake: bellRinging, vShake: bellFlashing),
        ]);

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
        elevation: 10.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: row,
        ));
  }

  List<Widget> buildPlayArea() {
    if (error.isNotEmpty) {
      return [Center(child: Text(error))];
    }
    switch (state) {
      case BuzzState.clientWaitingForServer:
        return clientWaitingForServer();
//      case BuzzState.clientWaitingToLogin:
//        return buildWaitingToLogin();
      case BuzzState.clientWaitingForCmd:
        return buildWaitingForCmd();
      case BuzzState.clientReady:
        return buildReady();
      default:
        return [Text('Bug State: $state')];
    }
  }

  ///////////////////////////////////////////
  ///
  void registerUs() async {
    if (id.isEmpty) {
      // Client just came up.
      // Register as new client
      final newId = await nanoid();
      setState(() {
        id = newId;
      });

      BuzzMsg msg =
          BuzzMsg(BuzzCmd.client, BuzzCmd.newClientRequest, {}, sourceId: id);
      await StaticSingleMultiCast.sendBuzzMsg(msg);
    }
  }

  /////////////////////////////////////////////
  ///
  startHeartbeatCheckTimer() {
    stoptHeartbeatCheckTimer();
    const dur = Duration(seconds: 3);
    heartbeatCheckTimer = Timer.periodic(dur, onHeartbeatCheckTimer);
  }

  onHeartbeatCheckTimer(_) async {
    Duration d = DateTime.now().difference(lastHeartbeatTime);
    final bool newAlive = d.inSeconds <= 3;
    setState(() {
      alive = newAlive;
    });
  }

  stoptHeartbeatCheckTimer() {
    heartbeatCheckTimer?.cancel();
  }

  ///////////////////////////////////////////////
  ///
  Future audioTheriyuma() async {
    AssetSource src = AssetSource("audio/Theriyuma.mp3");
    await audioPlayer.play(src);
  }

  Future ringBell() async {
    if (bellAudioEnabled) {
      audioPlayer.release();
      AssetSource src = AssetSource("audio/bell.mp3");
      await audioPlayer.play(src);
    }

    setState(() {
      bellRinging = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        bellRinging = false;
      });
    });
  }

  void flashBell() {
    setState(() {
      bellFlashing = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        bellFlashing = false;
      });
    });
  }

  ///////////////////////////////////////////////
  ///
  setBuzzState(newState) {
    Log.log("Setting state to $state");
    setState(() => state = newState);
  }

  /*
  void onLogin() async {
    if (!connected) {
      connectToServerAndListen();
    }

    if (!connected) {
      setState(() {
        error = "Socket not connected";
      });
      return;
    }

    final user = userController.text;
    if (user.isEmpty) return;

    final data = {"user": user};
    setState(() {
      userName = user;
    });
    final loginRequest = BuzzMsg(BuzzCmd.client, BuzzCmd.lgq, data);
    sendMessageToServer(loginRequest);

    setBuzzState(BuzzState.clientWaitingForCmd);
  }

  Widget buildWaitingToLogin() {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: userController,
              decoration: const InputDecoration(
                  hintText: 'Name', labelText: 'Enter Name'),
            ),
            ElevatedButton(onPressed: onLogin, child: const Text("Join")),
          ]),
    ));
  }

  Widget buildWaitingForLoginResponse() {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
          const Text("Connected. Waiting for Server Cmd"),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: sendPingToServer, child: const Text("PING")),
        ]));
    //return const Center(child: Text("Waiting for Login Response"));
  }

  Widget buildAreYouReady() {
    Widget actions = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton(onPressed: sendPingToServer, child: const Text("PING")),
        SizedBox(
            height: 100, //height of button
            width: 300, //width of button
            child: ElevatedButton(
                onPressed: sendIamReadyToServer,
                child: const Text("I AM READY"))),
      ],
    );

    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
          const Text("Connected. Waiting for Server Cmd"),
          const SizedBox(height: 20),
          actions
        ]));
  }

 */
  List<Widget> clientWaitingForServer() {
    return [const Center(child: Text("Ready To Play"))];
  }

  List<Widget> buildReady() {
    return [
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        WIDGETS.tamilText("பதில் தெரியுமா?", 30, color: Colors.black),
        const SizedBox(width: 30),
        WIDGETS.buildCountdownTime(secondsRemaining)
      ]),
      const SizedBox(height: 20),
      WIDGETS.noBuzzer(onBuzzedNo),
      const SizedBox(height: 100),
      WIDGETS.yesBuzzer(onBuzzedYes),
    ];
  }

  List<Widget> buildWaitingForCmd() {
    final children = <Widget>[];

    if (topBuzzers != null) {
      final int count = topBuzzers!["count"] ?? 0;
      if (count == 0) {
        children.add(const Center(
            child: Text("No one buzzed this time",
                style: TextStyle(fontSize: 30, color: Colors.red))));
      } else {
        children.add(Center(
            child: Text("Top $count Buzzers",
                style:
                    const TextStyle(fontSize: 30, color: Colors.green))));
        children.add(const Divider(
          height: 3,
        ));
        final List<dynamic> buzzers = topBuzzers!["buzzers"] ?? [];
        final String topId = topBuzzers!["topId"] ?? "";

        children.add(const SizedBox(height: 20.0));
        children.add(TopBuzzers(buzzers, id, topId));
        /*
        final List<dynamic> buzzers = topBuzzers!["buzzers"] ?? [];
        return TopBuzzers(buzzers);
        */
      }
    } else {
      children
          .add(const Center(child: Text("Connected. Waiting for Server Cmd")));
    }
    return children;
  }

  void onBuzzedYes() {
    final buzz = BuzzMsg(BuzzCmd.client, BuzzCmd.buzzYes, {}, sourceId: id);
    StaticSingleMultiCast.sendBuzzMsg(buzz);
  }

  void onBuzzedNo() {
    final buzz = BuzzMsg(BuzzCmd.client, BuzzCmd.buzzNo, {}, sourceId: id);
    StaticSingleMultiCast.sendBuzzMsg(buzz);
  }

  void sendPingToServer() {
    final ping = BuzzMsg(BuzzCmd.client, BuzzCmd.ping, {}, sourceId: id);
    StaticSingleMultiCast.sendBuzzMsg(ping);
  }

  /////////////////////////////////////////////////
  ///
  onServerMessage(BuzzMsg msg) {
    // Receiving our own message.
    if (msg.source == BuzzCmd.client) {
      return;
    }

    // We are not the target of this message;
    if (msg.targetId != id && msg.targetId != 'ALL') {
      return;
    }

    if (msg.cmd == BuzzCmd.hbq) {
      return processHeartbeat(msg);
    }

    if (msg.cmd == BuzzCmd.ping) {
      return processPing();
    }

    if (msg.cmd == BuzzCmd.pong) {
      return flashBell();
    }

    if (msg.cmd == BuzzCmd.newClientResponse) {
      return processNewClientResponse(msg);
    }

    if (msg.cmd == BuzzCmd.rejoinClientResponse) {
      return processRejoinClient(msg);
    }

    if (msg.cmd == BuzzCmd.startRound) {
      setBuzzState(BuzzState.clientReady);
      audioTheriyuma();
      return;
    }

    if (msg.cmd == BuzzCmd.endRound) {
      setState(() {
        topBuzzers = null;
      });
      setBuzzState(BuzzState.clientWaitingForCmd);
      return;
    }

    if (msg.cmd == BuzzCmd.countdown) {
      int sec = msg.data["sec"] ?? 0;
      setState(() {
        secondsRemaining = sec;
      });
      return;
    }

    if (msg.cmd == BuzzCmd.score) {
      int score = msg.data["score"] ?? 0;
      setState(() {
        myScore = score;
      });
      return;
    }

    if (msg.cmd == BuzzCmd.topBuzzers) {
      setState(() {
        topBuzzers = msg.data;
      });
    }
  }

  processPing() {
    // Server sent a ping.
    ringBell();
    final hb = BuzzMsg(BuzzCmd.client, BuzzCmd.pong, {}, sourceId: id);
    StaticSingleMultiCast.sendBuzzMsg(hb);
  }

  processHeartbeat(BuzzMsg msg) {
    lastHeartbeatTime = DateTime.now();

    // Race condition.
    // The client object is created but not registered and we dont have an ID.
    if (id.isNotEmpty) {
      final hb = BuzzMsg(BuzzCmd.client, BuzzCmd.hbr, {}, sourceId: id);
      StaticSingleMultiCast.sendBuzzMsg(hb);
    }
  }

  processNewClientResponse(BuzzMsg msg) {
    Log.log('processNewClient ${msg.toSocketMsg()}');
    setState(() {
      userName = msg.data["name"] ?? "Unknown";
    });
  }

  processRejoinClient(BuzzMsg msg) {
    Log.log('processRejoinClient');
  }

  /*
  // Process Server messages
  void handleServerMessage(IO.Socket socket, BuzzMsg msg) {
    Log.log('From Server: ${msg.toSocketMsg()}');

    setState(() {
      serverMessages.insert(0, msg);
    });

    if (msg.cmd == BuzzCmd.ping) {
      ringBell();
      final pong = BuzzMsg(BuzzCmd.client, BuzzCmd.pong, {});
      sendMessageToServer(pong);
    } else if (msg.cmd == BuzzCmd.pong) {
      flashBell();
    } else if (msg.cmd == BuzzCmd.showBuzz) {
      setBuzzState(BuzzState.clientReady);
      audioTheriyuma();
    } else if (msg.cmd == BuzzCmd.hideBuzz) {
      setState(() {
        topBuzzers = null;
      });
      setBuzzState(BuzzState.clientWaitingForCmd);
    } else if (msg.cmd == BuzzCmd.topBuzzers) {
      setState(() {
        topBuzzers = msg.data;
      });
    } else if (msg.cmd == BuzzCmd.countdown) {
      double sec = msg.data["sec"] ?? 0;
      setState(() {
        secondsRemaining = sec;
      });
    } else if (msg.cmd == BuzzCmd.score) {
      int score = msg.data["score"] ?? 0;
      setState(() {
        myScore = score;
      });
    }
  }
  */
}
