import 'package:buzzer/util/buzz_state.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:buzzer/util/log.dart';

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
  BuzzState state = BuzzState.serverWaitingToCreate;
  late final ServerSocket server;
  bool created = false;

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
    setState(() {
      created = true;
      state = BuzzState.serverWaitingForClients;
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
      clients.add("Unknown", client);
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
    final appBar = AppBar(
      title: const Text("Client"),
    );

    final availableHt =
        MediaQuery.of(context).size.height - appBar.preferredSize.height;
    final topPanelHeight = availableHt * 0.75;
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
        return buildClient(client);
      },
    );
  }

  Widget buildClient(BuzzClient client) {
    return Text(client.user);
  }

  Widget buildStatus() {
    switch (state) {
      case BuzzState.serverWaitingToCreate:
        return handleServerWaitingToCreat();
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

  Widget handleServerWaitingToCreat() {
    return WIDGETS.createServerButton(createServerAndListen);
  }

  Widget handleServerWaitingForClients() {
    return const Center(child: Text("Connected. Waiting for Clients"));
  }

  // Process Client messages
  void handleClientMessage(Socket client, BuzzMsg msg) {
    Log.log('From Client: ${msg.toSocketMsg()}');

    if (msg.cmd == BuzzCmd.lgq) {
      final data = msg.data;
      final user = data["user"] ?? "<null>";

      BuzzClient? c = clients.findBySocket(client);
      if (c != null) {
        setState(() {
          c.user = user;
        });
      }
    }
  }
}
