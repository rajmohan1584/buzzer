import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:buzzer/util/buzz_state.dart';
import 'package:buzzer/util/log.dart';
import 'package:buzzer/model/message.dart';
import 'package:buzzer/util/widgets.dart';
import 'dart:io';
import 'dart:typed_data';

import '../util/command.dart';

class BuzzClientScreen extends StatefulWidget {
  const BuzzClientScreen({super.key});

  @override
  State<BuzzClientScreen> createState() => _BuzzClientScreenState();
}

class _BuzzClientScreenState extends State<BuzzClientScreen> {
  late Socket? socket;
  BuzzState state = BuzzState.clientWaitingToJoin;
  bool connected = false;
  final userController = TextEditingController();
  String userName = "";
  List<BuzzMsg> serverMessages = [];
  final audioPlayer = AudioPlayer();

  @override
  void initState() {
    Log.log('Client InitState');
    userController.text = "Raj";
    super.initState();
    audio();
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
      socket!.write(s);
    }
  }

  Future<Socket?> connectToServer() async {
    Log.log('Connecting to server');
    final ip = InternetAddress.anyIPv4;
    const port = 5678;
    try {
      return await Socket.connect(ip, port);
    } catch (e) {
      Log.log(e.toString());
    }
    return null;
  }

  void connectToServerAndListen() async {
    socket = await connectToServer();

    if (socket == null) {
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
    socket!.write("Hello from Client");
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: WIDGETS.appBarTitle(name: userName),
    );

    final availableHt =
        MediaQuery.of(context).size.height - appBar.preferredSize.height;
    final topPanelHeight = availableHt * 0.15;
    final topPanelWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: appBar, body: buildBody(topPanelWidth, topPanelHeight));
  }

  Widget buildBody(w, h) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: w,
          height: h,
          child: buildClient(),
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

  void onLogin() {
    if (!connected) return;
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

    setBuzzState(BuzzState.clientWaitingForLoginResponse);
  }

  Widget buildWaitingToLogin() {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          TextField(
            controller: userController,
            decoration: const InputDecoration(
                hintText: 'Name', labelText: 'Enter Name'),
          ),
          ElevatedButton(onPressed: onLogin, child: const Text("Login")),
        ]));
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
          WIDGETS.noBuzzer(onBuzzedNo),
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
    } else if (msg.cmd == BuzzCmd.areYouReady) {
      setBuzzState(BuzzState.clientAreYouReady);
    }
  }
}
