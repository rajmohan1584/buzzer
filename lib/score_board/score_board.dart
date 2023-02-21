import 'dart:async';

import 'package:buzzer/util/buzz_state.dart';
import 'package:buzzer/util/log.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';

class BuzzScoreBoard extends StatefulWidget {
  const BuzzScoreBoard({super.key});

  @override
  State<BuzzScoreBoard> createState() => _BuzzScoreBoardState();
}

class _BuzzScoreBoardState extends State<BuzzScoreBoard> {
  BuzzState state = BuzzState.scoreBoardWaitingToJoin;
  bool connected = false;
  late Timer? _timer;

  @override
  void initState() {
    Log.log('ScoreBoard InitState');
    startTimer();
    super.initState();
  }

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }

  startTimer() {
    /*
    if (_timer?.isActive) {
      return;
    }
    */
    const dur = Duration(seconds: 1);
    _timer = Timer.periodic(dur, onTimer);
    onTimer(_timer);
  }

  onTimer(timer) {
    Log.log("On Timer");
  }

  stopTimer() {
    _timer?.cancel();
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
        setBuzzState(BuzzState.scoreBoardWaitingToJoin);
      },

      // handle server ending connection
      onDone: () {
        Log.log('Server left.');
        socket.destroy();
        setState(() => connected = false);
        setBuzzState(BuzzState.scoreBoardWaitingToJoin);
      },
    );

    setState(() => connected = true);
    setBuzzState(BuzzState.scoreBoardConnected);
    socket.write("Hello from ScoreBoard");
  }

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case BuzzState.scoreBoardWaitingToJoin:
        return handleWaitingToJoin();
      case BuzzState.scoreBoardConnected:
        return handleScoreBoardConnected();
      default:
        return Text('Bug State: $state');
    }
  }

  Widget handleWaitingToJoin() {
    return WIDGETS.joinButton(connectToServerAndListen);
  }

  Widget handleScoreBoardConnected() {
    return const Center(child: Text("Connected. Waiting for CMD"));
  }
}
