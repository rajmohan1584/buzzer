import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:buzzer/client/saved_user_datail.dart';
import 'package:buzzer/model/constants.dart';
import 'package:buzzer/model/game_cache.dart';
import 'package:buzzer/net/server_direct.dart';
import 'package:buzzer/util/language.dart';
import 'package:buzzer/widgets/top_buzzers.dart';
import 'package:flutter/material.dart';
import 'package:buzzer/util/buzz_state.dart';
import 'package:buzzer/util/log.dart';
import 'package:buzzer/model/message.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:nanoid/async.dart';

import '../model/defs.dart';
import '../net/single_multicast.dart';

const bool bellAudioEnabled = false;

class BuzzClientScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final int userAvatar;

  const BuzzClientScreen(this.userId, this.userName, this.userAvatar,
      {super.key});

  @override
  State<BuzzClientScreen> createState() => _BuzzClientScreenState();
}

class _BuzzClientScreenState extends State<BuzzClientScreen>
    with SingleTickerProviderStateMixin {
  BuzzState state = BuzzState.clientWaitingForServer;
  bool connected = false;
  final audioPlayer = AudioPlayer();
  String error = "";
  int secondsRemaining = 0;
  bool bellRinging = false;
  bool bellFlashing = false;
  Timer? heartbeatCheckTimer;
  DateTime lastHeartbeatTime = DateTime.now();
  bool alive = false;
  Map? topBuzzers;

  late String userId;
  late String userName;
  late int userAvatar;
  int userScore = 0;

  @override
  void initState() {
    userId = widget.userId;
    userName = widget.userName;
    userAvatar = widget.userAvatar;

    Log.log('Client InitState');
    ServerDirectReceiver.start();

    startHeartbeatCheckTimer();

    StaticSingleMultiCast.mainQueue.stream.listen((BuzzMsg msg) {
      onServerMessage(msg);
    });
    ServerDirectReceiver.androidInQueue.stream.listen((BuzzMsg msg) {
      onServerMessage(msg);
    });

    registerUs();

    super.initState();
  }

  @override
  void dispose() {
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

    Widget card = GestureDetector(
        onTap: () => {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SavedUserDetail()))
            },
        child: buildMyself());

    return Column(children: [
      card,
      const Divider(height: 2),
      const SizedBox(height: 30),
      ...children
    ]);
  }

  Widget buildMyself() {
    final color = alive ? CONST.textColor : Colors.red;

    final name = WIDGETS.clientName(userName);
    Widget row = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          WIDGETS.clientAvatar(userAvatar, color),
          name,
          WIDGETS.nameValue("SCORE", "$userScore", fontSize: 30.0),
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
    if (userId.isEmpty) {
      // Client just came up.
      // Register as new client
      //
      final newId = await nanoid();
      setState(() {
        userId = newId;
      });
    }

    // If the client has his own data - send it
    final BuzzMap data = {
      BuzzDef.id: userId,
      BuzzDef.name: userName,
      BuzzDef.nameUtf8: LANG.name2Socket(userName),
      BuzzDef.avatar: userAvatar
    };

    BuzzMsg msg = BuzzMsg(BuzzDef.client, BuzzDef.newClientRequest, data,
        sourceId: userId);
    await StaticSingleMultiCast.sendBuzzMsg(msg);
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
        WIDGETS.tamilText("பதில் தெரியுமா?", 30),
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
                style: const TextStyle(fontSize: 30, color: Colors.green))));
        children.add(const Divider(
          height: 3,
        ));
        final List<dynamic> buzzers = topBuzzers!["buzzers"] ?? [];
        final String topId = topBuzzers!["topId"] ?? "";

        children.add(const SizedBox(height: 20.0));
        children.add(TopBuzzers(buzzers, userId, topId));
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
    final buzz = BuzzMsg(BuzzDef.client, BuzzDef.buzzYes, {}, sourceId: userId);
    StaticSingleMultiCast.sendBuzzMsg(buzz);
  }

  void onBuzzedNo() {
    final buzz = BuzzMsg(BuzzDef.client, BuzzDef.buzzNo, {}, sourceId: userId);
    StaticSingleMultiCast.sendBuzzMsg(buzz);
  }

  void sendPingToServer() {
    final ping = BuzzMsg(BuzzDef.client, BuzzDef.ping, {}, sourceId: userId);
    StaticSingleMultiCast.sendBuzzMsg(ping);
  }

  /////////////////////////////////////////////////
  ///
  onServerMessage(BuzzMsg msg) {
    // Receiving our own message.
    if (msg.source == BuzzDef.client) {
      return;
    }

    // We are not the target of this message;
    if (msg.targetId != userId && msg.targetId != 'ALL') {
      return;
    }

    if (msg.cmd == BuzzDef.hbq) {
      return processHeartbeat(msg);
    }

    if (msg.cmd == BuzzDef.ping) {
      return processPing();
    }

    if (msg.cmd == BuzzDef.pong) {
      return flashBell();
    }

    if (msg.cmd == BuzzDef.newClientResponse) {
      return processNewClientResponse(msg);
    }

    if (msg.cmd == BuzzDef.startRound) {
      setBuzzState(BuzzState.clientReady);
      audioTheriyuma();
      return;
    }

    if (msg.cmd == BuzzDef.endRound) {
      setState(() {
        topBuzzers = null;
      });
      setBuzzState(BuzzState.clientWaitingForCmd);
      return;
    }

    if (msg.cmd == BuzzDef.countdown) {
      int sec = msg.data[BuzzDef.sec] ?? 0;
      setState(() {
        secondsRemaining = sec;
      });
      return;
    }

    if (msg.cmd == BuzzDef.score) {
      int score = msg.data[BuzzDef.score] ?? 0;
      setState(() {
        userScore = score;
      });
      return;
    }

    if (msg.cmd == BuzzDef.topBuzzers) {
      setState(() {
        topBuzzers = msg.data;
      });
    }
  }

  processPing() {
    // Server sent a ping.
    ringBell();
    final hb = BuzzMsg(BuzzDef.client, BuzzDef.pong, {}, sourceId: userId);
    StaticSingleMultiCast.sendBuzzMsg(hb);
  }

  processHeartbeat(BuzzMsg msg) {
    lastHeartbeatTime = DateTime.now();

    // Race condition.
    // The client object is created but not registered and we dont have an ID.
    if (userId.isNotEmpty) {
      final hb = BuzzMsg(BuzzDef.client, BuzzDef.hbr, {}, sourceId: userId);
      StaticSingleMultiCast.sendBuzzMsg(hb);
    }
  }

  processNewClientResponse(BuzzMsg msg) {
    Log.log('processNewClient ${msg.toSocketMsg()}');

    // Get the new client data from server
    String name = msg.data[BuzzDef.name] ?? "";
    StringUtf8 nameUtf8 = LANG.parseNameUtf8(msg.data);
    if (nameUtf8.isNotEmpty) name = LANG.socket2Name(nameUtf8);

    int avatar = msg.data[BuzzDef.avatar] ?? 0;
    int score = msg.data[BuzzDef.score] ?? 0;

    //
    // Cannot be empty
    // The server should return the data passed in by the client
    // or
    // If empty, the server should have assigned a new name and avatar
    //
    assert(name.isNotEmpty);
    assert(avatar >= 1);

    setState(() {
      userName = name;
      userAvatar = avatar;
      userScore = score;
    });

    GameCache.saveClientInCache(msg.data);
  }

  processRejoinClient(BuzzMsg msg) {
    Log.log('processRejoinClient');
  }
}
