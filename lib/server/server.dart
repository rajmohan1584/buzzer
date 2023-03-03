import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:buzzer/util/buzz_state.dart';
import 'package:buzzer/util/multicast.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:buzzer/util/log.dart';
import 'package:socket_io/socket_io.dart';

import '../model/client.dart';
import '../model/message.dart';
import '../util/command.dart';

class BuzzServerScreen extends StatefulWidget {
  const BuzzServerScreen({super.key});

  @override
  State<BuzzServerScreen> createState() => _BuzzServerScreenState();
}

class _BuzzServerScreenState extends State<BuzzServerScreen> {
  final BuzzClients clients = BuzzClients();
  BuzzState state = BuzzState.serverWaitingForClients;
  late final Server server;
  bool created = false;
  bool enableTimeout = true;
  double timeoutSeconds = 10;
  bool enableBuzzed = true;
  double buzzedCount = 3;
  double roundSecondsRemaining = 10;
  bool roundStarted = false;
  late DateTime roundStartTime;
  MulticastBroadcast mbroadcast = MulticastBroadcast();
  Timer? roundTimer;
  Timer? multicastTimer;
  final audioPlayer = AudioPlayer();

  @override
  void initState() {
    Log.log('Server InitState');
    createServerAndListen();
    startMulticastTimer();
    super.initState();
  }

  @override
  void dispose() {
    stopRoundTimer();
    stopMulticastTimer();
    audioPlayer.dispose();
    super.dispose();
  }

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

  ///////////////////////////
  //
  startMulticastTimer() {
    stopMulticastTimer();
    const dur = Duration(seconds: 1);
    //multicastTimer = Timer.periodic(dur, onMulticastTimer);
  }

  onMulticastTimer(_) {
    mbroadcast.broadcast("1.2.3.4");
  }

  stopMulticastTimer() {
    multicastTimer?.cancel();
  }

  void createServerAndListen() {
    const ip = "localhost";
    const port = 3000;
    const url = 'http://$ip:$port';

    Log.log('Creating server: $url');
    server = Server();
    server.on('connection', (client) {
      handleNewConnection(client);
    });
    server.listen(port);
  }

  void handleNewConnection(Socket client) {
    Log.log('New Connection');
    Log.log('Connection from ${client.id}');

    setState(() {
      BuzzClient? c = clients.add("Unknown", client);
      if (c != null) {
        c.created = DateTime.now();
        c.updated = DateTime.now();
        c.state = BuzzState.clientWaitingToLogin;
      }
    });

    client.on('disconnect', (_) {
      Log.log('Client left (disconnect)');
      handleCloseClient(client);
    });
    client.on('close', (_) {
      Log.log('Client left (close)');
      handleCloseClient(client);
    });
    client.on('msg', (data) {
      Log.log('Server reveived msg: $data');
      final BuzzMsg? msg = BuzzMsg.fromSocketIOMsg(data);
      if (msg == null) {
        Log.log("error");
        return;
      }
      handleClientMessage(client, msg);
    });
  }

  /*
  void createServerAndListen() async {
    Log.log('Creating server');
    //final ip = InternetAddress.anyIPv4;
    //final ip = CONST.iPhoneIp;
    const ip = 'localhost';
    const port = 5678;
    server = await ServerSocket.bind(ip, port);
    Log.log('Server created: ${server.address.address}: ${server.port}');
    setState(() {
      created = true;
    });
    // listen for clent connections to the server
    server.listen((Socket client) {
      handleNewConnection(client);
    });
  }

  void handleNewConnection(Socket client) {
    Log.log('New Connection');
    Log.log('Connection from'
        ' ${client.remoteAddress.address}:${client.remotePort}');

    setState(() {
      BuzzClient? c = clients.add("Unknown", client);
      if (c != null) {
        c.created = DateTime.now();
        c.updated = DateTime.now();
        c.state = BuzzState.clientWaitingToLogin;
      }
    });

    // listen for events from the client
    client.listen(
      // handle data from the client
      (Uint8List data) async {
        final BuzzMsg? msg = BuzzMsg.fromSocketMsg(data);
        if (msg == null) {
          Log.log("error");
          return;
        }
        handleClientMessage(client, msg);
      },

      // handle errors
      onError: (error) {
        Log.log(error);
        client.close();
        handleCloseClient(client);
      },

      // handle the client closing the connection
      onDone: () {
        Log.log('Client left');
        client.close();
        handleCloseClient(client);
      },
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: WIDGETS.appBarTitle(name: "நடுவர்"),
    );

    final availableHt =
        MediaQuery.of(context).size.height - appBar.preferredSize.height;
    final topPanelHeight = availableHt * 0.6;
    final topPanelWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
        onWillPop: () async {
          server.close();
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

    final name = Text(client.user,
        style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold));
    Widget row = IntrinsicWidth(
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(child: name),
      //Expanded(child: WIDGETS.nameValue('port', '${client.socket.remotePort}')),
      Expanded(child: WIDGETS.buzzedStatus(client.buzzedState, index)),
      Expanded(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          WIDGETS.plusIconButton(() => {}),
          WIDGETS.minusIconButton(() => {}),
          WIDGETS.bellIconButton(() => sendPingToClient(client),
              hShake: client.bellRinging, vShake: client.bellFlashing),
        ]),
      ),
    ]));

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
      case BuzzState.serverWaitingToCreate:
        return handleServerWaitingToCreate();
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

  Widget handleServerWaitingToCreate() {
    return WIDGETS.createServerButton(createServerAndListen);
  }

  Widget handleServerWaitingForClients0() {
    Widget actions = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton(
            onPressed: sendPingToAllClients, child: const Text("PING")),
        ElevatedButton(
            onPressed: sendAreYouReadyToAllClients,
            child: const Text("ARE YOU READY")),
      ],
    );

    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
          const Text("Connected"),
          const SizedBox(height: 20),
          actions,
        ]));
//    return const Center(child: Text("Connected. Waiting for Clients"));
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
    //sendTopBuzzersToAllClients();
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
          timout,
          buzzed,
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

  //
  void sendMessageToAllClients(BuzzMsg msg) {
    String s = msg.toSocketMsg();
    Log.log("sendMessage: $s");
    //socket.write(s);
    //List<int> list = utf8.encode(s);
    //Uint8List bytes = Uint8List.fromList(list);
    server.emit('msg', [s]);
  }

  //
  void showBuzzerToClient(BuzzClient client) {
    final showBuzz = BuzzMsg(BuzzCmd.server, BuzzCmd.showBuzz, {});
    client.sendMessage(showBuzz);
    setState(() {
      client.buzzedState = "";
    });
  }

  void showBuzzerToAllClients() {
    /*
    for (var i = 0; i < clients.length; i++) {
      showBuzzerToClient(clients[i]);
    }
    */
    for (var i = 0; i < clients.length; i++) {
      setState(() {
        clients[i].buzzedState = "";
      });
    }
    final showBuzz = BuzzMsg(BuzzCmd.server, BuzzCmd.showBuzz, {});
    sendMessageToAllClients(showBuzz);
  }

  //
  void hideBuzzerToClient(BuzzClient client) {
    final hideBuzz = BuzzMsg(BuzzCmd.server, BuzzCmd.hideBuzz, {});
    client.sendMessage(hideBuzz);
  }

  void hideBuzzerToAllClients() {
    /*
    for (var i = 0; i < clients.length; i++) {
      hideBuzzerToClient(clients[i]);
    }
    */
    final hideBuzz = BuzzMsg(BuzzCmd.server, BuzzCmd.hideBuzz, {});
    sendMessageToAllClients(hideBuzz);
  }

  //
  void sendPingToClient(BuzzClient client) {
    final ping = BuzzMsg(BuzzCmd.server, BuzzCmd.ping, {});
    client.sendMessage(ping);
  }

  void sendPingToAllClients() {
    /*
    for (var i = 0; i < clients.length; i++) {
      sendPingToClient(clients[i]);
    }
    */
    final ping = BuzzMsg(BuzzCmd.server, BuzzCmd.ping, {});
    sendMessageToAllClients(ping);
  }

  //
  void sendCountdownToClient(BuzzClient client) {
    final data = {"sec": roundSecondsRemaining};
    final countdown = BuzzMsg(BuzzCmd.server, BuzzCmd.countdown, data);

    client.sendMessage(countdown);
  }

  void sendCountdownToAllClients() {
    /*
    for (var i = 0; i < clients.length; i++) {
      sendCountdownToClient(clients[i]);
    }
    */
    final data = {"sec": roundSecondsRemaining};
    final countdown = BuzzMsg(BuzzCmd.server, BuzzCmd.countdown, data);
    sendMessageToAllClients(countdown);
  }

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
}
