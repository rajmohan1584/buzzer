import 'dart:io';

import 'package:buzzer/model/defs.dart';
import 'package:buzzer/model/message.dart';
import 'package:buzzer/util/log.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

Future<void> sleep(int ms) {
  Duration duration = Duration(milliseconds: ms);
  return Future.delayed(duration);
}

class ServerDirectReceiver {
  static final StreamController<BuzzMsg> androidInQueue =
      StreamController<BuzzMsg>();
  static String serverUrl = 'ws://192.168.50.69:8080';
  static late WebSocketChannel channel;
  static bool connected = false;

  // Function to handle incoming connections
  static Future<void> start() async {
    while (true) {
      try {
        if (!connected) {
          // Connect or reconnect
          channel = WebSocketChannel.connect(Uri.parse(serverUrl));

          Log.log('ServerDirectReceiver> WebSocketChannel connected:');

          channel.stream.listen((str) {
            final BuzzMsg? msg = BuzzMsg.fromString(str);
            if (msg != null) {
              if (msg.cmd != BuzzDef.hbq && msg.cmd != BuzzDef.hbr) {
                androidInQueue.add(msg);
              }
            } else {
              Log.log('ServerDirectReceiver> Received message: $str');
            }
          });

          Log.log('ServerDirectReceiver> WebSocketChannel Listening:');
          connected = true;
        }
      } catch (e) {
        connected = false;
        Log.log('ServerDirectReceiver> Exception: $e');
      }

      // Sleep
      Log.log('ServerDirectReceiver> Sleeping');
      await sleep(5000);
    }
  }
}


/*
import 'dart:async';

import 'package:bug_buzzer/log.dart';
import 'package:bug_buzzer/message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ServerDirect {
  static late WebSocketChannel ws;
  static final StreamController<BuzzMsg> webSocketQueue =
      StreamController<BuzzMsg>();

  static void start() {
    const ip = "localhost";
    const port = 1234;
    const uri = 'ws://$ip:$port';

    Log.log('ServerDirect> WebSocket: $uri');

    final wsUrl = Uri.parse(uri);
    ws = WebSocketChannel.connect(wsUrl);

    ws.stream.listen((str) {
      Log.log('ServerDirect> Client WebSocket reveived msg: $str');
      final BuzzMsg? msg = BuzzMsg.fromMulticastMessage(str);
      if (msg != null) {
        webSocketQueue.add(msg);
      }
    });
  }
}


*/
/*
import 'dart:async';
import 'dart:io';

import 'package:buzzer/model/message.dart';
import 'package:buzzer/util/log.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class ServerDirect {
  static late WebSocketChannel ws;
  static final StreamController<BuzzMsg> androidInQueue =
      StreamController<BuzzMsg>();

  static void start() {
    if (!Platform.isAndroid) {
      assert(false);
      return;
    }

    const ip = "localhost";
    const port = 1234;
    const uri = 'ws://$ip:$port';

    Log.log('ServerDirect> WebSocket: $uri');

    final wsUrl = Uri.parse(uri);
    ws = WebSocketChannel.connect(wsUrl);

    ws.stream.listen((str) {
      Log.log('ServerDirect> Client WebSocket reveived msg: $str');
      final BuzzMsg? msg = BuzzMsg.fromString(str);
      if (msg == null) {
        Log.log('error');
        return;
      }
      androidInQueue.add(msg);
    });
  }
}
*/
