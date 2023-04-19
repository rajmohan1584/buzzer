import 'dart:io';

import 'package:buzzer/model/constants.dart';
import 'package:buzzer/net/single_multicast.dart';
import 'package:buzzer/util/log.dart';
import 'dart:async';

// This is needed since android is unable to receive multicast messeges.
//
// Multiplexor will be created by the server (windows,macos,ios?)
// Any message coming thry the server multicast will be forwarded
//   to all android clients thru web-socket.
// Note that this is a one-way traffic.
// Messages are sent from the server (this) to all clients (android).
// No messages are expected from the clients. The clients use multicast
//   to send out messages.
//
class MultiplexorSender {
  static late HttpServer server;
  static final List<WebSocket> clients = [];

  static Future<void> start() async {
    // Listen to the androidOutQueue
    StaticSingleMultiCast.androidOutQueue.stream.listen((String s) {
      // Hack
      if (s != "S~HBQ~~ALL~{}") {
        Log.log(
            'MultiplexorSender> WebSocket Sent to ${clients.length} clients: $s');
      }

      // Forward all messages to all android clients.
      for (var client in clients) {
        client.add(s);
      }
    });

    // Create a http server
    server = await HttpServer.bind(CONST.myIP, 8080);

    Log.log(
        'MultiplexorSender> WebSocket server started on port ${server.port}');

    // Wait for new client connection
    server.listen((HttpRequest request) {
      Log.log('MultiplexorSender> WebSocket got a request. isUpgradeRequest');

      // New client connected.
      // Upgrade to web-socket
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        Log.log('MultiplexorSender> WebSocket upgrade');
        WebSocketTransformer.upgrade(request).then((WebSocket socket) {
          final remoteAddress = request.connectionInfo!.remoteAddress;
          final remotePort = request.connectionInfo!.remotePort;
          Log.log(
              'MultiplexorSender> WebSocket client connected: $remoteAddress:$remotePort');

          // Add the new client socket to a list.
          clients.add(socket);

          //
          // Wait and listen for messages from the client web-socket
          //
          Log.log('MultiplexorSender> WebSocket listen');
          socket.listen((dynamic data) {
            Log.log('MultiplexorSender> Received message from client: $data');
            // We dont expect any messages from client.
            assert(false);
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
