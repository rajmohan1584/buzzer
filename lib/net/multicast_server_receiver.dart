import 'dart:io';
//import 'dart:convert';

import 'package:buzzer/model/message.dart';
import 'package:buzzer/model/constants.dart';
import 'package:buzzer/util/log.dart';

import '../model/command.dart';
import 'package:udp/udp.dart';

//////////////////////////////////////////////////////
// Server use this to receive messages frpm client
// From clientMulticastIP:clientMulticastPort
//
class StaticServertMulticastListener {
  static var address = InternetAddress(CONST.clientMulticastIP);
  static var port = CONST.clientMulticastPort;
  static late RawDatagramSocket rawSocket;
  static Function(BuzzMsg)? callback;

  static void setCallback(Function(BuzzMsg) cb) {
    callback = cb;
  }

  static void removeCallback() {
    callback = null;
  }

  static Future initListener() async {
    rawSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
      reusePort: true,
      //multicastLoopback: true,
    );

    rawSocket.joinMulticast(address);

    rawSocket.listen((event) async {
      if (event == RawSocketEvent.read) {
        var datagram = rawSocket.receive();
        if (datagram != null) {
          final str = String.fromCharCodes(datagram.data);
          Log.log('StaticServertMulticastListener Received: $str');
          final BuzzMsg? msg = BuzzMsg.fromMulticastMessage(str);
          if (msg != null && callback != null) {
            //await callback!(msg);
          }
        }
      }
    });
  }

  void close() {
    try {
      rawSocket.close();
    } catch (e) {
      Log.log("ServertMulticastListener Multicast close error");
    }
  }
}
