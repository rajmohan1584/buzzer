import 'dart:io';
//import 'dart:convert';

import 'package:buzzer/model/message.dart';
import 'package:buzzer/model/constants.dart';
import 'package:buzzer/util/log.dart';

import '../model/command.dart';

//////////////////////////////////////////////////////
// Client use this to receive messages from server
// from serverMulticastIP:serverMulticastPort
//
class StaticClientMulticastListener {
  static var address = InternetAddress(CONST.serverMulticastIP);
  static var port = CONST.serverMulticastPort;
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
      //reusePort: true,
      //multicastLoopback: true,
    );

    rawSocket.joinMulticast(address);

    rawSocket.listen((event) {
      if (event == RawSocketEvent.read) {
        var datagram = rawSocket.receive();
        if (datagram != null) {
          final str = String.fromCharCodes(datagram.data);
          Log.log('ClientMulticastListener Received: $str');
          final BuzzMsg? msg = BuzzMsg.fromMulticastMessage(str);
          if (msg != null && callback != null) {
            callback!(msg);
          }
        }
      }
    });
  }

  void close() {
    try {
      rawSocket.close();
      //receiver.socket.close();
    } catch (e) {
      Log.log("ClientMulticastListener close error");
    }
  }
}
