import 'dart:async';
import 'dart:io';
//import 'dart:convert';

import 'package:buzzer/model/client.dart';
import 'package:buzzer/model/message.dart';
import 'package:buzzer/model/constants.dart';
import 'package:buzzer/util/log.dart';

import '../model/defs.dart';

class StaticSingleMultiCast {
  static final address = InternetAddress(CONST.multicastIP);
  static final port = CONST.multicastPort;

  static final StreamController<BuzzMsg> initialQueue =
      StreamController<BuzzMsg>();
  static final StreamController<BuzzMsg> mainQueue =
      StreamController<BuzzMsg>();
  static final StreamController<String> androidOutQueue =
      StreamController<String>();

  static Future initListener() async {
    late final RawDatagramSocket socket;
    if (Platform.isMacOS) {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
        reuseAddress: true,
        reusePort: true,
        //multicastLoopback: true,
      );
    } else {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
        reuseAddress: true,
        //reusePort: true,
        //multicastLoopback: true,
      );
    }
    socket.joinMulticast(address);

    socket.listen((event) async {
      if (event == RawSocketEvent.read) {
        var datagram = socket.receive();
        if (datagram != null) {
          final String str = String.fromCharCodes(datagram.data);

          // Add unfiltered messages to android multiplexor queue
          androidOutQueue.add(str);

          // Filter our own messages out
          final sourceAddress = datagram.address;
          if (sourceAddress != InternetAddress.anyIPv4 &&
              sourceAddress != InternetAddress.loopbackIPv4) {
            final BuzzMsg? msg = BuzzMsg.fromString(str);
            if (msg != null) {
              if (msg.cmd != BuzzDef.hbq && msg.cmd != BuzzDef.hbr) {
                Log.log('StaticSingleMultiCast Received: $str');
              }

              // Add this filtered message to the server queue
              initialQueue.add(msg);
              mainQueue.add(msg);
            } else {
              Log.log("WTF");
            }
          }
        }
      }
    });
  }

  static int send(String msg) {
    try {
      Log.log('StaticSingleMultiCast Sending multicast message: $msg');
      int bytes = -1;

      RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((socket) {
        bytes = socket.send(msg.codeUnits, address, port);
        socket.close();
      });

      Log.log('StaticSingleMultiCast Sent multicast bytes: $bytes');
      return bytes;
    } catch (e) {
      Log.log('Error $e');
      rethrow;
    }
  }

  static Future<int> awaitSend(String msg) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    int bytes = socket.send(msg.codeUnits, address, port);
    socket.close();
    return bytes;
  }

  static Future<int> sendBuzzMsg(BuzzMsg msg) async {
    String smsg = msg.toSocketMsg();
    if (msg.cmd != BuzzDef.hbq && msg.cmd != BuzzDef.hbr) {
      Log.log('StaticSingleMultiCast Sent sendBuzzMsg: $smsg');
    }
    return await awaitSend(smsg);
  }

  static void flush() {}
}
