import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:buzzer/model/game_cache.dart';
import 'package:buzzer/util/buzz_state.dart';
import 'package:buzzer/util/network.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:buzzer/util/log.dart';

import '../model/client.dart';
import '../model/message.dart';
import '../model/command.dart';
import '../model/constants.dart';
import '../net/single_multicast.dart';
import '../widets/int_spinner.dart';

class BuzzServerScreen extends StatefulWidget {
  const BuzzServerScreen({super.key});

  @override
  State<BuzzServerScreen> createState() => _BuzzServerScreenState();
}

class _BuzzServerScreenState extends State<BuzzServerScreen> {
  final BuzzClients clients = BuzzClients();
  BuzzState state = BuzzState.serverWaitingForClients;
  String myIP = "";
  String myWifi = "";
  bool created = false;
  bool enableTimeout = true;
  double timeoutSeconds = 10;
  bool enableBuzzed = true;
  double buzzedCount = 3;
  double roundSecondsRemaining = 10;
  bool roundStarted = false;
  late DateTime roundStartTime;
  Timer? roundTimer;
  Timer? multicastTimer;
  final audioPlayer = AudioPlayer();
  bool alive = false;

  @override
  void initState() {
    Log.log('Server InitState');
    startMulticastTimer();

    StaticSingleMultiCast.controller2.stream.listen((BuzzMsg msg) {
      onClientMessage(msg);
    });

    super.initState();
  }

  @override
  void dispose() {
    stopRoundTimer();
    stopMulticastTimer();
    audioPlayer.dispose();
    super.dispose();
  }

  ///////////////////////////////////////////
  // UI
  //
  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      leading: WIDGETS.heartbeatIcon(alive),
      title: WIDGETS.appBarTitle(name: "நடுவர்"),
    );

    final availableHt =
        MediaQuery.of(context).size.height - appBar.preferredSize.height;
    final topPanelHeight = availableHt * 0.6;
    final topPanelWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
        onWillPop: () async {
          // TODO - close multicast
          return true;
        },
        child: Scaffold(
            appBar: appBar, body: buildBody(topPanelWidth, topPanelHeight)));
  }

  Widget buildBody(w, h) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: w,
          height: h,
          child: buildClients(),
        ),
      ),
      const Divider(
        height: 2,
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: buildStatus(),
      )
    ]);
  }

  Widget buildClients() {
    final count = clients.length;
    if (count == 0) {
      // Waiting for clients.
      return Center(child: WIDGETS.waitingForClients());
    }
    return ListView.builder(
      itemCount: clients.length,
      itemBuilder: (context, int index) {
        BuzzClient client = clients.clients[index];
        // todo - call buildServer
        return buildClient(client, index);
      },
    );
  }

  Widget buildClient(BuzzClient client, int index) {
    /*
    Color color = COLORS.background["gray"]!;
    if (client.iAmReady) {
      color = COLORS.background["green"]!;
    } else {
      color = COLORS.background["yellow"]!;
    }
    */

    final name = Text(client.name,
        style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold));
    Widget row =
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(
          flex: 1,
          child: WIDGETS.bellIconButton(() => sendPingToClient(client),
              hShake: client.bellRinging, vShake: client.bellFlashing)),
      Expanded(flex: 5, child: name),
      //Expanded(child: WIDGETS.nameValue('port', '${client.socket.remotePort}')),
      Expanded(flex: 2, child: WIDGETS.buzzedStatus(client.buzzedState, index)),
      Expanded(
          flex: 3,
          child: IntSpinner(
              client.score,
              CONST.clientMinScore,
              CONST.clientMaxScore,
              (double v) => {onClientScoreChange(client, v.toInt())})),
    ]);

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
        elevation: 10.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: row,
        ));
  }

  Widget buildStatus() {
    switch (state) {
      case BuzzState.serverWaitingForClients:
        return handleServerWaitingForClients();
      case BuzzState.clientAreYouReady:
        return Text('Are You Ready: $state');
      case BuzzState.clientReady:
        return Text('Iam Ready: $state');
      default:
        return Text('Bug State: $state');
    }
  }

  ///////////////////////////////////////////////////////
  ///
  Future ringBell(BuzzClient c) async {
    AssetSource src = AssetSource("audio/bell.mp3");
    await audioPlayer.play(src);

    setState(() {
      c.bellRinging = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        c.bellRinging = false;
      });
    });
  }

  void flashBell(BuzzClient c) {
    setState(() {
      c.bellFlashing = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        c.bellFlashing = false;
      });
    });
  }

  startRoundTimer() {
    stopRoundTimer();
    const dur = Duration(seconds: 1);
    roundTimer = Timer.periodic(dur, onRoundTimer);
    setState(() {
      roundStartTime = DateTime.now();
      roundSecondsRemaining = timeoutSeconds;
      Log.log('startRoundTimer remaining:$roundSecondsRemaining');
    });
    onRoundTimer(roundTimer);
  }

  onRoundTimer(_) {
    final now = DateTime.now();
    final duration = now.difference(roundStartTime);
    setState(() {
      roundSecondsRemaining = timeoutSeconds - duration.inSeconds;
      Log.log('onRoundTimer remaining:$roundSecondsRemaining');
      if (roundSecondsRemaining <= 0) {
        onStopRound();
      }
    });
    sendCountdownToAllClients();
  }

  stopRoundTimer() {
    roundTimer?.cancel();
  }

  /////////////////////////////////////////////////////
  ///
  startMulticastTimer() {
    stopMulticastTimer();
    const dur = Duration(seconds: 5);
    multicastTimer = Timer.periodic(dur, onMulticastTimer);
  }

  onMulticastTimer(_) async {
    try {
      // Send heartbeat
      final BuzzMsg hb =
          BuzzMsg(BuzzCmd.server, BuzzCmd.hbq, {}, targetId: 'ALL');
      final int bytes = StaticSingleMultiCast.sendBuzzMsg(hb);
      if (bytes > 0 && !alive) {
        setState(() {
          alive = true;
        });
      }
    } catch (e) {
      Log.log(e);
      setState(() {
        alive = false;
      });
      startMulticastTimer(); // Start calls stop?
    }
  }

  stopMulticastTimer() {
    multicastTimer?.cancel();
  }

  onClientScoreChange(BuzzClient client, int score) {
    setState(() {
      client.score = score;
      sendScoreToClient(client);
    });
  }

  /////////////////////////////////////////////////
  ///
  Future onClientMessage(BuzzMsg msg) async {
    // Assert that there is no cross talk.
    assert(msg.source == BuzzCmd.client);

    if (msg.cmd == BuzzCmd.newClientRequest) {
      await processNewClient(msg);
    }

    if (msg.cmd == BuzzCmd.rejoinClientRequest) {
      await processRejoinClient(msg);
    }

    Log.log('onClientMessage - complete');
  }

  Future processNewClient(BuzzMsg msg) async {
    assert(msg.cmd == BuzzCmd.newClientRequest);
    // ID is generated by the client - so that we can use the same id to send
    final String id = msg.data["id"] ?? "";
    String name = await GameCache.addNewClient(id);

    // Successful add of new client will return new server-assigned name
    final BuzzMsg ncResponse = BuzzMsg(
        BuzzCmd.server, BuzzCmd.newClientResponse, {"name": name},
        targetId: id);

    Log.log(ncResponse.toSocketMsg());
    //multicastSender.sendBuzzMsg(ncResponse);
    GameCache.dump();
  }

  processRejoinClient(BuzzMsg msg) {
    assert(msg.cmd == BuzzCmd.rejoinClientRequest);

    final String id = msg.data["id"];
    final String name = msg.data["name"];
    // TODO GameCache.addRejoinClient(id, name);
    GameCache.dump();
  }

  void onChangeEnableTimeout(bool enable) {
    setState(() {
      enableTimeout = enable;
    });
  }

  void onTimeoutSecondsChange(double timeout) {
    setState(() {
      timeoutSeconds = timeout;
    });
  }

  void onChangeEnableBuzzed(bool enable) {
    setState(() {
      enableBuzzed = enable;
    });
  }

  void onBuzzedCountChange(double count) {
    setState(() {
      buzzedCount = count;
    });
  }

  void onStartRound() {
    setState(() {
      roundStarted = true;
    });
    showBuzzerToAllClients();
    startRoundTimer();
  }

  void onStopRound() {
    setState(() {
      roundStarted = false;
    });
    stopRoundTimer();
    sendCountdownToAllClients();
    hideBuzzerToAllClients();
    sendTopBuzzersToAllClients();
  }

  Widget buildStartStop() {
    int groupValue = roundStarted ? 0 : 1;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(10),
      child: CupertinoSlidingSegmentedControl<int>(
        padding: const EdgeInsets.all(8),
        groupValue: groupValue,
        children: const {
          0: Text("Start Round"),
          1: Text("Stop Round"),
        },
        onValueChanged: (value) {
          if (value == 0) {
            onStartRound();
          } else {
            onStopRound();
          }
        },
      ),
    );
  }

  Widget handleServerWaitingForClients() {
    final counts = clients.counts;
    final total = counts[0],
        yes = counts[1],
        no = counts[2],
        pending = counts[3];
    Widget status = Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          WIDGETS.nameValue("மொத்தம்", "$total"),
          WIDGETS.nameValue("தெரியும்", "$yes"),
          WIDGETS.nameValue("தெரியாது", "$no"),
          WIDGETS.nameValue("தூக்கம்", "$pending"),
        ]);

    Widget buttons = Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildStartStop(),
          WIDGETS.buildCountdownTime(roundSecondsRemaining),
          //WIDGETS.button("Show Buzzer", showBuzzerToAllClients),
          //WIDGETS.button("Hide Buzzer", hideBuzzerToAllClients),
          WIDGETS.button("PING", sendPingToAllClients),
        ]);

    Widget timout = WIDGETS.switchRowWithInput(
        "Auto Stop Timeout Seconds",
        enableTimeout,
        onChangeEnableTimeout,
        timeoutSeconds,
        onTimeoutSecondsChange);

    Widget buzzed = WIDGETS.switchRowWithInput("Auto Stop on தெரியும் Count",
        enableBuzzed, onChangeEnableBuzzed, buzzedCount, onBuzzedCountChange);

    final child = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          status,
          const SizedBox(height: 5),
          const Divider(height: 2, thickness: 2),
          const SizedBox(height: 5),
          timout,
          buzzed,
          const SizedBox(height: 5),
          const Divider(height: 2, thickness: 2),
          buttons
        ]);

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
        elevation: 10.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: child,
        ));

//    return const Center(child: Text("Connected. Waiting for Clients"));
  }

  /*
  // Process Client messages
  void handleClientMessage(Socket client, BuzzMsg msg) {
    Log.log('From Client: ${msg.toSocketMsg()}');

    BuzzClient? c = clients.findBySocket(client);
    final data = msg.data;

    if (c != null) {
      setState(() {
        c.serverMsg = msg;
      });
      if (msg.cmd == BuzzCmd.lgq) {
        final user = data["user"] ?? "<null>";

        setState(() {
          c.user = user;
          c.updated = DateTime.now();
        });

        // Send login response
        final lgr = BuzzMsg(BuzzCmd.server, BuzzCmd.lgr, {});
        c.sendMessage(lgr);
      } else if (msg.cmd == BuzzCmd.ping) {
        ringBell(c);
        final pong = BuzzMsg(BuzzCmd.server, BuzzCmd.pong, {});
        c.sendMessage(pong);
      } else if (msg.cmd == BuzzCmd.pong) {
        flashBell(c);
      } else if (msg.cmd == BuzzCmd.iAmReady) {
        setState(() {
          c.iAmReady = data["ready"] ?? false;
          c.updated = DateTime.now();
          clients.sortByReadyUpdated();
        });
      } else if (msg.cmd == BuzzCmd.buzzYes || msg.cmd == BuzzCmd.buzzNo) {
        setState(() {
          c.buzzedState = msg.cmd;
          c.updated = DateTime.now();
          clients.sortByBuzzedUpdated();
        });

        final counts = clients.counts;
        final total = counts[0], yes = counts[1], no = counts[2];
        if (total == yes + no) {
          // Round Done.
          onStopRound();
        }
        if (enableBuzzed && yes == buzzedCount) {
          // Round Donw
          onStopRound();
        }
      }
    }
  }

  void handleCloseClient(Socket client) {
    Log.log('Closing Client: ${client.toString()}');
    setState(() {
      clients.remove(client);
    });
  }
  */

  void sendScoreToClient(BuzzClient client) {
    final data = {"score": client.score};
    final score =
        BuzzMsg(BuzzCmd.server, BuzzCmd.score, data, targetId: client.id);
    StaticSingleMultiCast.sendBuzzMsg(score);
  }

  void sendTopBuzzersToAllClients() {
    clients.sortByBuzzedUpdated();

    // Get the top buzzedCount clients.
    final data = clients.getTopBuzzedData(buzzedCount.toInt());

    final topBuzzers =
        BuzzMsg(BuzzCmd.server, BuzzCmd.topBuzzers, data, targetId: "ALL");
    StaticSingleMultiCast.sendBuzzMsg(topBuzzers);
  }

  void showBuzzerToAllClients() {
    for (var i = 0; i < clients.length; i++) {
      setState(() {
        clients[i].buzzedState = "";
      });
    }
    final showBuzz =
        BuzzMsg(BuzzCmd.server, BuzzCmd.showBuzz, {}, targetId: 'ALL');
    StaticSingleMultiCast.sendBuzzMsg(showBuzz);
  }

  void hideBuzzerToAllClients() {
    final hideBuzz =
        BuzzMsg(BuzzCmd.server, BuzzCmd.hideBuzz, {}, targetId: 'ALL');
    StaticSingleMultiCast.sendBuzzMsg(hideBuzz);
  }

  void sendPingToClient(BuzzClient client) {
    final ping = BuzzMsg(BuzzCmd.server, BuzzCmd.ping, {}, targetId: client.id);
    StaticSingleMultiCast.sendBuzzMsg(ping);
  }

  void sendPingToAllClients() {
    final ping = BuzzMsg(BuzzCmd.server, BuzzCmd.ping, {}, targetId: 'ALL');
    StaticSingleMultiCast.sendBuzzMsg(ping);
  }

  void sendCountdownToAllClients() {
    final data = {"sec": roundSecondsRemaining};
    final countdown =
        BuzzMsg(BuzzCmd.server, BuzzCmd.countdown, data, targetId: 'ALL');
    StaticSingleMultiCast.sendBuzzMsg(countdown);
  }

  /*
  //
  void sendAreYouReadyToClient(BuzzClient client) {
    final areYouReady = BuzzMsg(BuzzCmd.server, BuzzCmd.areYouReady, {});
    client.sendMessage(areYouReady);
    setState(() {
      client.buzzedState = "";
      client.iAmReady = false;
      client.updated = DateTime.now();
    });
  }

  void sendAreYouReadyToAllClients() {
    for (var i = 0; i < clients.length; i++) {
      sendAreYouReadyToClient(clients[i]);
    }
  }
  */
}
