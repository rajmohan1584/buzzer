import 'package:audioplayers/audioplayers.dart';
//import 'package:buzzer/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:buzzer/util/buzz_state.dart';
import 'package:buzzer/util/log.dart';
import 'package:buzzer/model/message.dart';
import 'package:buzzer/util/widgets.dart';
//import 'dart:io';
//import 'dart:typed_data';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';

import '../util/command.dart';

class BuzzClientScreen extends StatefulWidget {
  const BuzzClientScreen({super.key});

  @override
  State<BuzzClientScreen> createState() => _BuzzClientScreenState();
}

class _BuzzClientScreenState extends State<BuzzClientScreen> {
  late IO.Socket? socket;
  BuzzState state = BuzzState.clientWaitingToLogin;
  bool connected = false;
  final userController = TextEditingController();
  String userName = "";
  List<BuzzMsg> serverMessages = [];
  final audioPlayer = AudioPlayer();
  String error = "";
  double secondsRemaining = 0;

  @override
  void initState() {
    Log.log('Client InitState');
    userController.text = "Raj";
    connectToServerAndListen();
    super.initState();
  }

  Future audio() async {
    AssetSource src = AssetSource("audio/Theriyuma.mp3");
    await audioPlayer.play(src);
  }

  @override
  void dispose() {
    userController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  setBuzzState(newState) {
    Log.log("Setting state to $state");
    setState(() => state = newState);
  }

  void sendMessageToServer(BuzzMsg msg) {
    if (socket == null) {
      Log.log("error");
    } else {
      String s = msg.toSocketMsg();
      Log.log("sendMessageToServer: $s");
      socket!.emit('msg', s);
    }
  }

  void connectToServer() {
    const ip = "localhost";
    const port = 5678;
    const url = 'http://$ip:$port';
    socket = IO.io(url);
  }

  void connectToServerAndListen() {
    connectToServer();
    if (!socket!.connected) {
      setState(() {
        error = "Unable to connect to server";
      });
      return;
    }

    socket!.on('connect', (_) {
      setState(() => connected = true);
      setBuzzState(BuzzState.clientWaitingToLogin);
    });
    socket!.on('disconnect', (_) {
      Log.log('Server left.');
      socket!.destroy();
      setState(() => connected = false);
      setBuzzState(BuzzState.clientWaitingToJoin);
    });
    socket!.on('msg', (data) {
      final BuzzMsg? msg = BuzzMsg.fromSocketMsg(data);
      if (msg == null) {
        Log.log('error');
        return;
      }

      handleServerMessage(socket!, msg);
    });
  }
  /*
  Future<Socket?> connectToServer() async {
    Log.log('');
    //final ip = InternetAddress.anyIPv4;
    //final ip = CONST.iPhoneIp;
    const ip = "localhost";
    const port = 5678;
    try {
      Log.log('Connecting to server: $ip: $port');
      return await Socket.connect(ip, port);
    } catch (e) {
      Log.log(e.toString());
    }
    return null;
  }

  Future connectToServerAndListen() async {
    socket = await connectToServer();

    if (socket == null) {
      setState(() {
        error = "Unable to connect to server";
      });
      return;
    }

    Log.log(
        'Connected to: ${socket!.remoteAddress.address}:${socket!.remotePort}');

    // listen for responses from the server
    socket!.listen(
      // handle data from the server
      (Uint8List data) {
        final BuzzMsg? msg = BuzzMsg.fromSocketMsg(data);
        if (msg == null) {
          Log.log('error');
          return;
        }

        handleServerMessage(socket!, msg);
      },

      // handle errors
      onError: (error) {
        Log.log(error);
        socket!.destroy();
        setState(() => connected = false);
        setBuzzState(BuzzState.clientWaitingToJoin);
      },

      // handle server ending connection
      onDone: () {
        Log.log('Server left.');
        socket!.destroy();
        setState(() => connected = false);
        setBuzzState(BuzzState.clientWaitingToJoin);
      },
    );

    setState(() => connected = true);
    setBuzzState(BuzzState.clientWaitingToLogin);
  }
  */

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: WIDGETS.appBarTitle(name: userName),
    );

    return WillPopScope(
        onWillPop: () async {
          socket?.close();
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
        children: [name, WIDGETS.nameValue("SCORE", "0")]);

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
        elevation: 10.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: row,
        ));
  }

  Widget buildPlayArea() {
    if (error.isNotEmpty) {
      return Center(child: Text(error));
    }
    switch (state) {
      case BuzzState.clientWaitingToLogin:
        return buildWaitingToLogin();
      case BuzzState.clientWaitingForCmd:
        return buildWaitingForCmd();
      case BuzzState.clientReady:
        return buildReady();
      default:
        return Text('Bug State: $state');
    }
  }

  Widget buildClient() {
    return ListView.builder(
      itemCount: serverMessages.length,
      itemBuilder: (context, int index) {
        String msg = serverMessages[index].toString();
        // todo - call buildServer
        return Text(msg, style: const TextStyle(fontSize: 20));
      },
    );
  }

  Widget buildStatus() {
    if (error.isNotEmpty) {
      return Center(child: Text(error));
    }
    switch (state) {
      case BuzzState.clientWaitingToJoin:
        return buildWaitingToJoin();
      case BuzzState.clientWaitingToLogin:
        return buildWaitingToLogin();
      case BuzzState.clientWaitingForLoginResponse:
        return buildWaitingForLoginResponse();
      case BuzzState.clientWaitingForCmd:
        return buildWaitingForCmd();
      case BuzzState.clientAreYouReady:
        return buildAreYouReady();
      case BuzzState.clientReady:
        return buildReady();
      default:
        return Text('Bug State: $state');
    }
  }

  Widget buildWaitingToJoin() {
    return WIDGETS.joinButton(connectToServerAndListen);
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
    /*
    String loginMsg = loginRequest.toSocketMsg();
    Log.log("onLogin: $loginMsg}");
    socket!.write(loginMsg);
    */

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
            const SizedBox(height: 30),
            WIDGETS.buildCountdownTime(secondsRemaining)
          ]),
          const SizedBox(height: 20),
          WIDGETS.noBuzzer(onBuzzedNo),
          const SizedBox(height: 100),
          WIDGETS.yesBuzzer(onBuzzedYes),
        ]));
  }

  /*
  void onBuzzed() {
    final buzz = BuzzMsg(BuzzCmd.client, BuzzCmd.buzz, {});
    sendMessageToServer(buzz);
  }
  */

  void onBuzzedYes() {
    final buzz = BuzzMsg(BuzzCmd.client, BuzzCmd.buzzYes, {});
    sendMessageToServer(buzz);
  }

  void onBuzzedNo() {
    final buzz = BuzzMsg(BuzzCmd.client, BuzzCmd.buzzNo, {});
    sendMessageToServer(buzz);
  }

  void sendPingToServer() {
    final ping = BuzzMsg(BuzzCmd.client, BuzzCmd.ping, {});
    sendMessageToServer(ping);
  }

  void sendIamReadyToServer() {
    final data = {"ready": true};
    final ping = BuzzMsg(BuzzCmd.server, BuzzCmd.iAmReady, data);
    sendMessageToServer(ping);
    setBuzzState(BuzzState.clientReady);
    audio();
  }

  // Process Server messages
  void handleServerMessage(Socket socket, BuzzMsg msg) {
    Log.log('From Server: ${msg.toSocketMsg()}');

    setState(() {
      serverMessages.insert(0, msg);
    });

    if (msg.cmd == BuzzCmd.ping) {
      final pong = BuzzMsg(BuzzCmd.client, BuzzCmd.pong, {});
      sendMessageToServer(pong);
    } else if (msg.cmd == BuzzCmd.showBuzz) {
      setBuzzState(BuzzState.clientReady);
      audio();
    } else if (msg.cmd == BuzzCmd.hideBuzz) {
      setBuzzState(BuzzState.clientWaitingForCmd);
    } else if (msg.cmd == BuzzCmd.countdown) {
      double sec = msg.data["sec"] ?? 0;
      setState(() {
        secondsRemaining = sec;
      });
    }
  }
}
