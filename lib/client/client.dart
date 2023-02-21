import 'package:flutter/material.dart';
import 'package:buzzer/util/buzz_state.dart';
import 'package:buzzer/util/log.dart';
import 'package:buzzer/model/message.dart';
import 'package:buzzer/util/widgets.dart';
import 'dart:io';
import 'dart:typed_data';

import '../util/command.dart';

class BuzzClient extends StatefulWidget {
  const BuzzClient({super.key});

  @override
  State<BuzzClient> createState() => _BuzzClientState();
}

class _BuzzClientState extends State<BuzzClient> {
  late Socket? socket;
  BuzzState state = BuzzState.clientWaitingToJoin;
  bool connected = false;
  final userController = TextEditingController();

  @override
  void initState() {
    Log.log('Client InitState');
    userController.text = "Raj";
    super.initState();
  }

  @override
  void dispose() {
    userController.dispose();
    super.dispose();
  }

  setBuzzState(newState) {
    Log.log("Setting state to $state");
    setState(() => state = newState);
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
    return Scaffold(
        appBar: AppBar(
          title: const Text("Client"),
        ),
        body: Center(child: buildBody()));
  }

  Widget buildBody() {
    switch (state) {
      case BuzzState.clientWaitingToJoin:
        return handleWaitingToJoin();
      case BuzzState.clientWaitingToLogin:
        return handleWaitingToLogin();
      case BuzzState.clientWaitingForLoginResponse:
        return handleWaitingForLoginResponse();
      case BuzzState.clientWaitingForCmd:
        return handleWaitingForCmd();
      case BuzzState.clientAreYouReady:
        return Text('Are You Ready: $state');
      case BuzzState.clientReady:
        return Text('Iam Ready: $state');
      default:
        return Text('Bug State: $state');
    }
  }

  Widget handleWaitingToJoin() {
    return WIDGETS.joinButton(connectToServerAndListen);
  }

  void onLogin() {
    if (!connected) return;
    final user = userController.text;
    if (user.isEmpty) return;

    final data = {"user": user};

    final loginRequest = BuzzMsg(BuzzCmd.client, BuzzCmd.lgq, data);
    String loginMsg = loginRequest.toSocketMsg();
    Log.log("onLogin: $loginMsg}");
    socket!.write(loginMsg);

    setBuzzState(BuzzState.clientWaitingForLoginResponse);
  }

  Widget handleWaitingToLogin() {
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

  Widget handleWaitingForLoginResponse() {
    return const Center(child: Text("Waiting for Login Response"));
  }

  Widget handleWaitingForCmd() {
    return const Center(child: Text("Connected. Waiting for Server Cmd"));
  }

  // Process Server messages
  void handleServerMessage(Socket socket, BuzzMsg msg) {
    Log.log('From Server: ${msg.toSocketMsg()}');
  }
}
