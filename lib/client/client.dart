import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:buzzer/widets/top_buzzers.dart';
import 'package:flutter/material.dart';
import 'package:buzzer/util/buzz_state.dart';
import 'package:buzzer/util/log.dart';
import 'package:buzzer/model/message.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:nanoid/async.dart';

import '../model/command.dart';
import '../net/multicast.dart';

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
  double secondsRemaining = 0;
  bool bellRinging = false;
  bool bellFlashing = false;
  Timer? multicastCheckTimer;
  bool alive = false;
  Map? topBuzzers;
  bool firstTime = true;

  ClientMulticastSender multicastSender = ClientMulticastSender();
  ClientMulticastListener multicastReceiver = ClientMulticastListener();

  @override
  void initState() {
    Log.log('Client InitState');
    userController.text = "Raj";
    startMulticastCheckTimer();
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
      title: WIDGETS.appBarTitle(name: userName),
    );

    return WillPopScope(
        onWillPop: () async {
          // socket.close();
          return true;
        },
        child: Scaffold(appBar: appBar, body: buildBody()));
  }

  Widget buildBody() {
    return Column(
        children: [buildMyself(), const Divider(height: 2), buildPlayArea()]);
  }

  Widget buildMyself() {
    final name = Text(userName,
        style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold));
    Widget row = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          name,
          WIDGETS.nameValue("SCORE", "$myScore"),
          WIDGETS.bellIconButton(() => sendPingToServer(),
              hShake: bellRinging, vShake: bellFlashing),
        ]);

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
        elevation: 10.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: row,
        ));
  }

  Widget buildPlayArea() {
    /*
    if (error.isNotEmpty) {
      return Center(child: Text(error));
    }
    switch (state) {
      case BuzzState.clientWaitingForServer:
        return clientWaitingForServer();
      case BuzzState.clientWaitingToLogin:
        return buildWaitingToLogin();
      case BuzzState.clientWaitingForCmd:
        return buildWaitingForCmd();
      case BuzzState.clientReady:
        return buildReady();
      default:
        return Text('Bug State: $state');
    }
    */
    return const Text('TODO');
  }

  /////////////////////////////////////////////
  ///
  registerWithServer() async {
    // The nanoid is always generated the client on a newAdd.
    final String id = await nanoid();

    BuzzMsg addNew =
        BuzzMsg(BuzzCmd.client, BuzzCmd.newClientRequest, {"id": id});
    multicastSender.sendBuzzMsg(addNew);
  }

  /////////////////////////////////////////////
  ///
  startMulticastCheckTimer() {
    stoptMulticastCheckTimer();
    const dur = Duration(seconds: 3);
    multicastCheckTimer = Timer.periodic(dur, onMulticastCheckTimer);
  }

  onMulticastCheckTimer(_) async {
    // First time.
    if (firstTime) {
      await multicastSender.init();
      await multicastReceiver.init();
      await multicastReceiver.listen(onServerMessage);
      registerWithServer();
      firstTime = false;
    }
    /*
    Duration d = DateTime.now().difference(MulticastListenerNew.lastUpdateTime);
    final bool newAlive = d.inSeconds <= 3;
    setState(() {
      alive = newAlive;
    });

    final ip = MulticastListenerNew.serverData;
    if (ip.isNotEmpty && state == BuzzState.clientWaitingForServer) {
      setState(() {
        serverIP = ip;
        connectToServerAndListen();
      });
    }
    */
  }

  stoptMulticastCheckTimer() {
    multicastCheckTimer?.cancel();
  }

  ///////////////////////////////////////////////
  ///
  Future audioTheriyuma() async {
    AssetSource src = AssetSource("audio/Theriyuma.mp3");
    await audioPlayer.play(src);
  }

  Future ringBell() async {
    AssetSource src = AssetSource("audio/bell.mp3");
    await audioPlayer.play(src);

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
  Widget clientWaitingForServer() {
    return const Center(child: Text("Waiting for Server"));
  }

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

  Widget buildWaitingForCmd() {
    if (topBuzzers != null) {
      final int count = topBuzzers!["count"] ?? 0;
      if (count == 0) {
        return const Center(child: Text("No one buzzed this time"));
      }

      final List<dynamic> buzzers = topBuzzers!["buzzers"] ?? [];
      return TopBuzzers(buzzers);
    }
    return const Center(child: Text("Connected. Waiting for Server Cmd"));
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

  Widget buildReady() {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
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
        ]));
  }
  */

  /*
  void onBuzzed() {
    final buzz = BuzzMsg(BuzzCmd.client, BuzzCmd.buzz, {});
    sendMessageToServer(buzz);
  }
  */

  void onBuzzedYes() {
    final buzz = BuzzMsg(BuzzCmd.client, BuzzCmd.buzzYes, {}, sourceId: id);
    multicastSender.sendBuzzMsg(buzz);
  }

  void onBuzzedNo() {
    final buzz = BuzzMsg(BuzzCmd.client, BuzzCmd.buzzNo, {}, sourceId: id);
    multicastSender.sendBuzzMsg(buzz);
  }

  void sendPingToServer() {
    final ping = BuzzMsg(BuzzCmd.client, BuzzCmd.ping, {}, sourceId: id);
    multicastSender.sendBuzzMsg(ping);
  }

  /////////////////////////////////////////////////
  ///
  onServerMessage(BuzzMsg msg) {
    // Assert that there is no cross talk.
    assert(msg.source == BuzzCmd.server);

    // if this message is not for us. Skip
    if (msg.targetId != id && msg.targetId != 'ALL') return;

    if (msg.cmd == BuzzCmd.newClientResponse) {
      return processNewClientResponse(msg);
    }

    if (msg.cmd == BuzzCmd.rejoinClientResponse) {
      return processRejoinClient(msg);
    }
  }

  processNewClientResponse(BuzzMsg msg) {
    Log.log('processNewClient');
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

  showTopBuzzers(data) {}
}
