import 'package:buzzer/buzz_state.dart';
import 'package:buzzer/util/log.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';

class BuzzClient extends StatefulWidget {
  const BuzzClient({super.key});

  @override
  State<BuzzClient> createState() => _BuzzClientState();
}

class _BuzzClientState extends State<BuzzClient> {
  BuzzState state = BuzzState.clientWaitingToJoin;
  bool connected = false;

  @override
  void initState() {
    Log.log('Client InitState');
    super.initState();
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
    final socket = await connectToServer();

    if (socket == null) {
      return;
    }

    Log.log(
        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');

    // listen for responses from the server
    socket.listen(
      // handle data from the server
      (Uint8List data) {
        final msg = String.fromCharCodes(data);
        Log.log('From Server: $msg');
      },

      // handle errors
      onError: (error) {
        Log.log(error);
        socket.destroy();
        setState(() => connected = false);
        setBuzzState(BuzzState.clientWaitingToJoin);
      },

      // handle server ending connection
      onDone: () {
        Log.log('Server left.');
        socket.destroy();
        setState(() => connected = false);
        setBuzzState(BuzzState.clientWaitingToJoin);
      },
    );

    setState(() => connected = true);
    setBuzzState(BuzzState.clientWaitingForCmd);
    socket.write("Hello from Client");
  }

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case BuzzState.clientWaitingToJoin:
        return handleWaitingToJoin();
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

  Widget handleWaitingForCmd() {
    return const Center(child: Text("Connected. Waiting for CMD"));
  }
}
