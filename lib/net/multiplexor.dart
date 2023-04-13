import 'dart:io';

import 'package:buzzer/net/single_multicast.dart';
import 'package:buzzer/util/log.dart';
import 'package:socket_io/socket_io.dart';

class Multiplexor {
  //
  // Listens to the multicast queue of the server
  //
  static late Server server;

  static createServerAndListen() {
    const ip = "localhost";
    const port = 3000;
    const url = 'http://$ip:$port';

    Log.log('Multiplexor> Creating server: $url');
    server = Server();
    server.on('connection', (client) {
      handleNewConnection(client);
    });
    server.listen(port);

    StaticSingleMultiCast.androidOutQueue.stream.listen((String s) {
      Log.log('Multiplexor> emmiting $s');
      server.emit('msg', [s]);
    });
  }

  static handleNewConnection(Socket client) {
    Log.log('Multiplexor> New Connection');
    Log.log('Multiplexor> Connection from ${client.id}');

    client.on('disconnect', (_) {
      Log.log('Multiplexor> Client left (disconnect)');
    });
    client.on('close', (_) {
      Log.log('Multiplexor> Client left (close)');
    });
    client.on('msg', (data) {
      Log.log('Multiplexor> Server reveived msg: $data');
      // This is a one way traffic to android.
      // Noing should come from android.
      assert(false);
    });
  }
}
