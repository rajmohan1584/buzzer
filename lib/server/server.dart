import 'package:buzzer/buzz_state.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:buzzer/util/log.dart';

class BuzzServer extends StatefulWidget {
  const BuzzServer({super.key});

  @override
  State<BuzzServer> createState() => _BuzzServerState();
}

class _BuzzServerState extends State<BuzzServer> {
  BuzzState state = BuzzState.serverWaitingToCreate;
  late final ServerSocket server;

  @override
  void initState() {
    Log.log('Server InitState');
    super.initState();
  }

  void createServerAndListen() async {
    Log.log('Creating server');
    final ip = InternetAddress.anyIPv4;
    const port = 5678;
    server = await ServerSocket.bind(ip, port);
    Log.log('Server created: ${ip.address}: $port');
    // listen for clent connections to the server
    server.listen((client) {
      handleNewConnection(client);
    });
  }

  void handleNewConnection(Socket client) {
    Log.log('New Connection');
    Log.log('Connection from'
        ' ${client.remoteAddress.address}:${client.remotePort}');

    // listen for events from the client
    client.listen(
      // handle data from the client
      (Uint8List data) async {
        await Future.delayed(const Duration(seconds: 1));
        final msg = String.fromCharCodes(data);
        Log.log('From Client: $msg');

        client.write('Got your message');
      },

      // handle errors
      onError: (error) {
        Log.log(error);
        client.close();
      },

      // handle the client closing the connection
      onDone: () {
        Log.log('Client left');
        client.close();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case BuzzState.serverWaitingToCreate:
        return handleServerWaitingToCreat();
      case BuzzState.clientAreYouReady:
        return Text('Are You Ready: $state');
      case BuzzState.clientReady:
        return Text('Iam Ready: $state');
      default:
        return Text('Bug State: $state');
    }
  }

  Widget handleServerWaitingToCreat() {
    return WIDGETS.createServerButton(createServerAndListen);
  }
}
