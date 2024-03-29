import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:buzzer/model/game_cache.dart';
import 'package:buzzer/model/server.dart';
import 'package:buzzer/model/server_settings.dart';
import 'package:buzzer/net/multiplexor.dart';
import 'package:buzzer/server/client_detail.dart';
import 'package:buzzer/server/helper.dart';
import 'package:buzzer/server/server_settings.dart';
import 'package:buzzer/util/buzz_state.dart';
import 'package:buzzer/util/language.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:buzzer/widgets/double_switch.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:buzzer/util/log.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:buzzer/model/client.dart';
import 'package:buzzer/model/message.dart';
import 'package:buzzer/model/defs.dart';
import 'package:buzzer/net/single_multicast.dart';

const bool bellAudioEnabled = false;

class BuzzServerScreen extends StatefulWidget {
  const BuzzServerScreen({super.key});

  @override
  State<BuzzServerScreen> createState() => _BuzzServerScreenState();
}

class _BuzzServerScreenState extends State<BuzzServerScreen> {
  final BuzzServer server = BuzzServer();
  BuzzState state = BuzzState.serverWaitingForClients;
  String myIP = "";
  String myWifi = "";
  bool created = false;
  int roundSecondsRemaining = 10;
  bool roundStarted = false;
  late DateTime roundStartTime;
  DateTime? prevYesBuzzTime;
  Timer? roundTimer;
  Timer? multicastTimer;
  final audioPlayer = AudioPlayer();
  bool serverAlive = false;
  ServerSettings settings = ServerSettings();
  DoubleButtonController dbController = DoubleButtonController();
  final int heartBeatSeconds = 1;

  @override
  void initState() {
    Log.log('Server InitState');
    settings.loadFromCache();
    server.loadFromCache();

    dbController.addListener(handleHandleDoubleButtonChange);

    startMulticastTimer();

    StaticSingleMultiCast.mainQueue.stream.listen((BuzzMsg msg) {
      // Assert that there is no cross talk.
      if (msg.source == BuzzDef.server) {
        // Our own message
        return;
      }

      // Messages from a particular client
      BuzzClient? client = server.findById(msg.sourceId);

      // Race condition
      // Client has an id but server has not processed the registration
      //    to create a client card.
      if (client != null) {
        if (msg.cmd == BuzzDef.newClientRequest) {
          //
          // The client could is RE-JOINING the game.
          // Could be a name change or a avatar change
          // But comming from the same device
          //
          processRejoinClient(client, msg);
          return;
        }
        onClientMessage(msg, client);
        return;
      }

      // Race condition
      // Client has an id but server has not processed the registration
      //    to create a client card - and a client's HBR sneeks thru
      if (msg.cmd == BuzzDef.hbr) return;

      // Here we process and create a new client card.
      assert(msg.cmd == BuzzDef.newClientRequest);
      processNewClient(msg);
    });

    if (Platform.isWindows) {
      MultiplexorSender.start();
    }
    super.initState();
  }

  @override
  void dispose() {
    dbController.removeListener(handleHandleDoubleButtonChange);
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
      leading: WIDGETS.heartbeatIcon(serverAlive),
      title: WIDGETS.appBarTitle(name: "நடுவர்"),
    );

    final availableHt =
        MediaQuery.of(context).size.height - appBar.preferredSize.height;
    final topPanelHeight = availableHt * .7;
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
        height: 5,
        color: Colors.grey,
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: buildStatus(),
      )
    ]);
  }

  Widget buildClients() {
    final count = server.length;
    if (count == 0) {
      // Waiting for clients.
      return Center(child: WIDGETS.waitingForClients());
    }

    if (settings.viewMode == "grid") {
      return GridView.builder(
          itemCount: server.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2,
          ),
          itemBuilder: (context, int index) {
            BuzzClient client = server.clients[index];
            // todo - call buildServer
            return GestureDetector(
                onTap: () => {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ClientDetail(client,
                                  sendPingToClient, onClientScoreChange)))
                    },
                child: buildGridClient(client, index));
          });
    }

    return ListView.builder(
      itemCount: server.length,
      itemBuilder: (context, int index) {
        BuzzClient client = server.clients[index];
        // todo - call buildServer
        return GestureDetector(
            onTap: () => {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ClientDetail(
                              client, sendPingToClient, onClientScoreChange)))
                },
            child: buildSlidableClient(client, index));
      },
    );
  }

  //////////////////////////////////////
  //
  Widget buildSlidableClient(client, index) {
    return Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
                backgroundColor: const Color.fromARGB(255, 199, 152, 152),
                foregroundColor: Colors.white,
                onPressed: (_) => {},
                icon: CupertinoIcons.exclamationmark_circle,
                label: 'Warning'),
            SlidableAction(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                onPressed: (_) => {onDeleteClient(client, index)},
                icon: CupertinoIcons.delete,
                label: 'Delete')
          ],
        ),
        child: ServerHelper.buildClient(
            client, sendPingToClient, onClientScoreChange));
  }

  ////////////////////////////////////////////
  ///
  Widget buildGridClient(client, index) {
    final name = Text(client.name, style: const TextStyle(fontSize: 20.0));

    final bell = WIDGETS.bellIconButton(() => sendPingToClient(client),
        hShake: client.bellRinging, vShake: client.bellFlashing);
    final score =
        Text("${client.score}", style: const TextStyle(fontSize: 30.0));
    final buzzedStatus =
        WIDGETS.buzzedStatus(client.buzzedState, client.buzzedYesDelta);

    final row = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [bell, buzzedStatus, score]));

    final column = Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [name, row]);

    final Color color = client.alive ? Colors.green : Colors.red;

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5.0),
        elevation: 10.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: ClipPath(
            clipper: ShapeBorderClipper(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: Container(
                decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: color, width: 12))),
                child: Padding(
                  padding: const EdgeInsets.all(.0),
                  child: column,
                ))));
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
    if (bellAudioEnabled) {
      audioPlayer.release();
      AssetSource src = AssetSource("audio/bell.mp3");
      await audioPlayer.play(src);
    }

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

  ///////////////////////////////////////////////////////
  ///
  startRoundTimer() {
    stopRoundTimer();
    const dur = Duration(seconds: 1);
    roundTimer = Timer.periodic(dur, onRoundTimer);
    setState(() {
      roundSecondsRemaining = settings.timeoutSeconds;
      Log.log('startRoundTimer remaining:$roundSecondsRemaining');
    });
    onRoundTimer(roundTimer);
  }

  onRoundTimer(_) {
    final now = DateTime.now();
    final duration = now.difference(roundStartTime);
    setState(() {
      roundSecondsRemaining = settings.timeoutSeconds - duration.inSeconds;
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
    final dur = Duration(seconds: heartBeatSeconds);
    multicastTimer = Timer.periodic(dur, onMulticastTimer);
  }

  onMulticastTimer(_) async {
    try {
      // Send heartbeat
      final BuzzMsg hb =
          BuzzMsg(BuzzDef.server, BuzzDef.hbq, {}, targetId: 'ALL');
      final int bytes = await StaticSingleMultiCast.sendBuzzMsg(hb);
      if (bytes > 0 && !serverAlive) {
        setState(() {
          serverAlive = true;
        });
      }
    } catch (e) {
      Log.log(e);
      setState(() {
        serverAlive = false;
      });
      stopMulticastTimer(); // Start calls stop?
      startMulticastTimer(); // Start calls stop?
    }

    setState(() {
      server.performHealthCheck();
    });
  }

  stopMulticastTimer() {
    multicastTimer?.cancel();
  }

  ///////////////////////////////////////////////////////
  ///
  onClientScoreChange(BuzzClient client, int score) {
    setState(() {
      client.setScore(score);
      sendScoreToClient(client);
    });
    server.saveInCache();
  }

  void onStartRound() {
    setState(() {
      roundStarted = true;
      prevYesBuzzTime = null;
      roundStartTime = DateTime.now();
    });
    showBuzzerToAllClients();
    startRoundTimer();
  }

  void onStopRound() {
    setState(() {
      // Stop the round
      roundStarted = false;
      // Reset the DoubleButton
      dbController.reset();
    });
    stopRoundTimer();
    sendCountdownToAllClients();
    hideBuzzerToAllClients();
    sendTopBuzzersToAllClients();
  }

  Widget buildStartStop0() {
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

  Widget buildStartStop() {
    return DoubleButton(dbController);
  }

  handleHandleDoubleButtonChange() {
    if (dbController.sw2Checked) {
      Log.log('Start Rount');
      onStartRound();
    } else {
      if (roundStarted) {
        Log.log('Stop Round');
        onStopRound();
      }
    }
  }

  Widget handleServerWaitingForClients() {
    final counts = server.counts;
    final total = counts[0],
        alive = counts[1],
        dead = counts[2],
        yes = counts[3],
        no = counts[4],
        pending = counts[5];

    Widget statusRow = Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          WIDGETS.nameValue("மொத்தம்", "$total"),
          WIDGETS.nameValue("அலைவ்", "$alive"),
          WIDGETS.nameValue("டெட்", "$dead"),
          WIDGETS.nameValue("தெரியும்", "$yes/${settings.buzzedCount}"),
          WIDGETS.nameValue("தெரியாது", "$no"),
          WIDGETS.nameValue("நோட்டா", "$pending"),
        ]);

    final settingsSegue = WIDGETS.segueIconButton(() async {
      final result = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ServerSettingsScreen(settings)));

      // When a BuildContext is used from a StatefulWidget, the mounted property
      // must be checked after an asynchronous gap.
      if (!mounted) return;

      if (result != null) {
        setState(() {
          settings = result;
        });
        settings.saveInCache();
      }
    });
    final settingsSegue2 = GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ServerSettingsScreen(settings)));

          // When a BuildContext is used from a StatefulWidget, the mounted property
          // must be checked after an asynchronous gap.
          if (!mounted) return;

          if (result != null) {
            setState(() {
              settings = result;
            });
          }
        },
        child: const Icon(CupertinoIcons.right_chevron));

    Widget actionsRow = Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildStartStop(),
          WIDGETS.buildCountdownTime(roundSecondsRemaining),
          WIDGETS.bellIconButton(sendPingToAllClients),
          settingsSegue
        ]);

    final child = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          statusRow,
          const SizedBox(height: 5),
          const Divider(height: 2, thickness: 2),
          const SizedBox(height: 5),
          actionsRow
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
    final BuzzMap data = {BuzzDef.score: client.score};
    final score =
        BuzzMsg(BuzzDef.server, BuzzDef.score, data, targetId: client.id);
    StaticSingleMultiCast.sendBuzzMsg(score);
  }

  void sendTopBuzzersToAllClients() {
    server.sortByBuzzedUpdated();

    // Get the top buzzedCount clients.
    final data = server.getTopBuzzedData(settings.buzzedCount);

    final topBuzzers =
        BuzzMsg(BuzzDef.server, BuzzDef.topBuzzers, data, targetId: "ALL");
    StaticSingleMultiCast.sendBuzzMsg(topBuzzers);
  }

  void showBuzzerToAllClients() {
    for (var i = 0; i < server.length; i++) {
      setState(() {
        server[i].buzzedState = "";
        server[i].buzzedYesDelta = null;
      });
    }
    final showBuzz =
        BuzzMsg(BuzzDef.server, BuzzDef.startRound, {}, targetId: 'ALL');
    StaticSingleMultiCast.sendBuzzMsg(showBuzz);
  }

  void hideBuzzerToAllClients() {
    final hideBuzz =
        BuzzMsg(BuzzDef.server, BuzzDef.endRound, {}, targetId: 'ALL');
    StaticSingleMultiCast.sendBuzzMsg(hideBuzz);
  }

  void sendCountdownToAllClients() {
    final BuzzMap data = {BuzzDef.sec: roundSecondsRemaining};
    final countdown =
        BuzzMsg(BuzzDef.server, BuzzDef.countdown, data, targetId: 'ALL');
    StaticSingleMultiCast.sendBuzzMsg(countdown);
  }

  ////////////////////////////////////////////////////////
  ///
  /// Sending client messages
  ///
  void sendPingToClient(BuzzClient client) {
    final ping = BuzzMsg(BuzzDef.server, BuzzDef.ping, {}, targetId: client.id);
    StaticSingleMultiCast.sendBuzzMsg(ping);
  }

  void sendPingToAllClients() {
    final ping = BuzzMsg(BuzzDef.server, BuzzDef.ping, {}, targetId: 'ALL');
    StaticSingleMultiCast.sendBuzzMsg(ping);
  }

  ////////////////////////////////////////////////////
  ///
  /// Delete the client
  ///
  onDeleteClient(BuzzClient client, int index) {
    setState(() {
      server.removeClient(client.id);
    });
  }

  /////////////////////////////////////////////////////////////////////////
  ///
  /// Receiving client messages
  ///
  Future onClientMessage(BuzzMsg msg, BuzzClient client) async {
    if (msg.cmd == BuzzDef.hbr) {
      await processHeartbeatResponse(msg);
      return;
    }

    if (msg.cmd == BuzzDef.ping) {
      processPing(client);
      return;
    }

    if (msg.cmd == BuzzDef.pong) {
      // client is responding to a server ping.
      flashBell(client);
      return;
    }

    if (msg.cmd == BuzzDef.buzzYes || msg.cmd == BuzzDef.buzzNo) {
      processClientBuzz(client, msg);
      return;
    }

    if (msg.cmd == BuzzDef.updateClientRequest) {
      processUpdateClientRequest(client, msg);
      return;
    }

    Log.log('onClientMessage - Unknown Message ${msg.toSocketMsg()}');
    assert(false);
  }

  processPing(BuzzClient client) {
    // Client is pinging server.
    ringBell(client);
    final pong = BuzzMsg(BuzzDef.server, BuzzDef.pong, {}, targetId: client.id);
    StaticSingleMultiCast.sendBuzzMsg(pong);
  }

  processHeartbeatResponse(BuzzMsg msg) {
    final String id = msg.sourceId;
    final BuzzClient? client = server.findById(id);
    assert(client != null);
    client?.updated = DateTime.now();
  }

  processClientBuzz(BuzzClient client, BuzzMsg msg) {
    setState(() {
      client.buzzedState = msg.cmd;
      client.updated = DateTime.now();
      if (msg.cmd == BuzzDef.buzzYes) {
        if (prevYesBuzzTime == null) {
          // This is the first buzzer
          client.buzzedYesDelta = client.updated.difference(roundStartTime);
        } else {
          client.buzzedYesDelta = client.updated.difference(prevYesBuzzTime!);
        }
        prevYesBuzzTime = client.updated;
      }
      server.sortByBuzzedUpdated();
    });

    final counts = server.counts;
    final total = counts[0], yes = counts[3], no = counts[4];

    if (total == yes + no) {
      // Round Done.
      onStopRound();
    }
    if (settings.enableBuzzed && yes == settings.buzzedCount) {
      // Round Done
      onStopRound();
    }
  }

  ///////////////////////////////////////////////////////////////////
  ///
  Future processNewClient(BuzzMsg msg) async {
    assert(msg.cmd == BuzzDef.newClientRequest);
    // ID is generated by the client - so that we can use the same id to send
    final String id = msg.sourceId;
    BuzzMap newData = await GameCache.addNewClient(msg.data);

    // Successful add of new client.
    // Create a new client card.
    setState(() {
      server.addClient(newData);
    });

    // return new server-assigned name
    final BuzzMsg ncResponse = BuzzMsg(
        BuzzDef.server, BuzzDef.newClientResponse, newData,
        targetId: id);

    Log.log(ncResponse.toSocketMsg());
    StaticSingleMultiCast.sendBuzzMsg(ncResponse);

    server.saveInCache();
  }

  ///////////////////////////////////////////////////////////////////
  ///
  processRejoinClient(BuzzClient client, BuzzMsg msg) {
    assert(msg.cmd == BuzzDef.newClientRequest); // same message

    String id = msg.data[BuzzDef.id];
    assert(client.id == id);

    String name = msg.data[BuzzDef.name];
    StringUtf8 nameUtf8 = msg.data[BuzzDef.nameUtf8] ?? [];
    int avatar = msg.data[BuzzDef.avatar];
    if (nameUtf8.isNotEmpty) name = LANG.socket2Name(nameUtf8);

    if (name.isEmpty) name = GameCache.getNextClientName();
    if (avatar < 0) avatar = 0;

    setState(() {
      client.setName(name);
      client.setNameUtf8(nameUtf8);
      client.setAvatar(avatar);

      msg.data[BuzzDef.name] = name;
      msg.data[BuzzDef.nameUtf8] = LANG.name2Socket(name);
      msg.data[BuzzDef.avatar] = avatar;
      msg.data[BuzzDef.score] = client.score;
    });

    final BuzzMsg ncResponse = BuzzMsg(
        BuzzDef.server, BuzzDef.newClientResponse, msg.data,
        targetId: id);

    Log.log(ncResponse.toSocketMsg());
    StaticSingleMultiCast.sendBuzzMsg(ncResponse);

    server.saveInCache();
  }

  processUpdateClientRequest(BuzzClient client, BuzzMsg msg) {
    String newName = msg.data[BuzzDef.name] ?? "";
    StringUtf8 nameUtf8 = LANG.parseNameUtf8(msg.data);
    if (nameUtf8.isNotEmpty) newName = LANG.socket2Name(nameUtf8);
    final int newAvatar = msg.data[BuzzDef.avatar] ?? 0;

    if (newName.isEmpty) {
      newName = GameCache.getNextClientName();
    }
    setState(() {
      client.setName(newName);
      client.setAvatar(newAvatar);
    });

    msg.data[BuzzDef.name] = newName;
    msg.data[BuzzDef.nameUtf8] = LANG.name2Socket(newName);
    msg.data[BuzzDef.avatar] = newAvatar;

    BuzzMsg updateResponseMsg = BuzzMsg(
        BuzzDef.server, BuzzDef.updateClientResponse, msg.data,
        targetId: msg.sourceId);
    StaticSingleMultiCast.sendBuzzMsg(updateResponseMsg);

    server.saveInCache();
  }
}
