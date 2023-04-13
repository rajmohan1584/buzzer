import 'dart:async';
import 'dart:io';

import 'package:buzzer/model/message.dart';
import 'package:buzzer/util/log.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ServerDirect {
  static late IO.Socket socket;
  static final StreamController<BuzzMsg> androidInQueue =
      StreamController<BuzzMsg>();

  static void _connectToServer() {
    const ip = "localhost";
    const port = 3000;
    const url = 'http://$ip:$port';

    Log.log('ServerDirect> Connecting to server: $url');

    //socket = IO.io(url);

    socket = IO.io(
        url,
        IO.OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            .disableAutoConnect() // disable auto-connection
            .build());
    socket.connect();
  }

  static void connectToServerAndListen() {
    if (!Platform.isAndroid) return;

    _connectToServer();
    socket.onConnect((data) {
      Log.log('ServerDirect> Connected to server');
    });
    socket.on('connect', (_) {
      Log.log('ServerDirect> Connected to server');
    });
    socket.on('disconnect', (_) {
      Log.log('ServerDirect> Disconnected from server');
      socket.destroy();
    });
    socket.on('msg', (data) {
      Log.log('ServerDirect> Client reveived msg: $data');
      final BuzzMsg? msg = BuzzMsg.fromString(data[0]);
      if (msg == null) {
        Log.log('error');
        return;
      }
      androidInQueue.add(msg);
    });
    socket.on('event', (data) {
      Log.log('ServerDirect> Client reveiced event: $data');
    });
  }
}
