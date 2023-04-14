import 'dart:io';

import 'package:buzzer/model/message.dart';
import 'package:buzzer/net/single_multicast.dart';
import 'package:buzzer/util/log.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:async';

class MultiplexorSender {
  static late HttpServer server;
  static final List<WebSocket> clients = [];

  static Future<void> start() async {
    StaticSingleMultiCast.androidOutQueue.stream.listen((String s) {
      Log.log(
          'MultiplexorSender> WebSocket Sent to ${clients.length} clients: $s');
      for (var client in clients) {
        client.add(s);
      }
    });
    server = await HttpServer.bind('192.168.50.69', 8080);

    Log.log(
        'MultiplexorSender> WebSocket server started on port ${server.port}');

    server.listen((HttpRequest request) {
      Log.log('MultiplexorSender> WebSocket got a request. isUpgradeRequest');

      if (WebSocketTransformer.isUpgradeRequest(request)) {
        Log.log('MultiplexorSender> WebSocket upgrade');
        WebSocketTransformer.upgrade(request).then((WebSocket socket) {
          final remoteAddress = request.connectionInfo!.remoteAddress;
          final remotePort = request.connectionInfo!.remotePort;
          clients.add(socket);

          Log.log(
              'MultiplexorSender> WebSocket client connected: $remoteAddress:$remotePort');

          Log.log('MultiplexorSender> WebSocket listen');
          socket.listen((dynamic data) {
            Log.log('MultiplexorSender> Received message from client: $data');
            // Process the received message as needed
          }, onError: (dynamic error) {
            Log.log('MultiplexorSender> onError Error occurred: $error');
            clients.remove(socket);
          }, onDone: () {
            Log.log('MultiplexorSender> onDone WebSocket client disconnected');
            clients.remove(socket);
          });
        }).catchError((dynamic error) {
          Log.log(
              'MultiplexorSender> Failed to upgrade WebSocket connection: $error');
        });
      }
    });
  }
}

/*
import 'package:buzzer/net/single_multicast.dart';
import 'package:buzzer/util/log.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Multiplexor {
  //
  // Listens to the multicast queue of the server
  //
  static late WebSocketChannel ws;

  static createServerAndListen() {
    const ip = "localhost";
    const port = 1234;

    const uri = 'ws://$ip:$port';
    Log.log('Multiplexor> WebSocket: $uri');

    final wsUrl = Uri.parse(uri);
    ws = WebSocketChannel.connect(wsUrl);

    StaticSingleMultiCast.androidOutQueue.stream.listen((String s) {
      Log.log('Multiplexor> emmiting $s');
      ws.sink.add(s);
    });
  }
}
*/
