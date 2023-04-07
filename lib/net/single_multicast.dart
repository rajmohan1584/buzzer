import 'dart:async';
import 'dart:io';
//import 'dart:convert';

import 'package:buzzer/model/message.dart';
import 'package:buzzer/model/constants.dart';
import 'package:buzzer/util/log.dart';

import '../model/command.dart';

class StaticSingleMultiCast {
  static final address = InternetAddress(CONST.multicastIP);
  static final port = CONST.multicastPort;
  static final StreamController<BuzzMsg> controller =
      StreamController<BuzzMsg>();

  static Future initListener() async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
      //reusePort: true,
      //multicastLoopback: true,
    );

    socket.joinMulticast(address);

    socket.listen((event) async {
      if (event == RawSocketEvent.read) {
        var datagram = socket.receive();
        if (datagram != null) {
          // Filter our own messages out
          final sourceAddress = datagram.address;
          if (sourceAddress != InternetAddress.anyIPv4 &&
              sourceAddress != InternetAddress.loopbackIPv4) {
            final str = String.fromCharCodes(datagram.data);
            Log.log('StaticSingleMultiCast Received: $str');
            final BuzzMsg? msg = BuzzMsg.fromMulticastMessage(str);
            if (msg != null) {
              controller.add(msg);
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

  static int sendBuzzMsg(BuzzMsg msg) {
    String smsg = msg.toSocketMsg();
    if (msg.cmd != BuzzCmd.hbq) {
      Log.log('StaticSingleMultiCast Sent sendBuzzMsg: $smsg');
    }
    return send(smsg);
  }

  static void flush() {}
}
