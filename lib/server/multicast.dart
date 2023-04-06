import 'dart:io';
//import 'dart:convert';

import 'package:buzzer/model/message.dart';
import 'package:buzzer/util/constants.dart';
import 'package:buzzer/util/log.dart';
import 'package:udp/udp.dart';

// Server uses this to send messages.
class ServerMulticastSender {
  final Endpoint multicastEndpoint = Endpoint.multicast(
      InternetAddress(CONST.serverMulticastIP),
      port: Port(CONST.serverMulticastPort));
  late UDP sender;

  Future init() async {
    sender = await UDP.bind(Endpoint.any());
  }

  Future<int> send(String msg) async {
    try {
      //Log.log('Sending multicast message: $msg');
      int bytes = await sender.send(msg.codeUnits, multicastEndpoint);
      //Log.log('Sent multicast bytes: $bytes');
      return bytes;
    } catch (e) {
      Log.log('Error $e');
      rethrow;
    }
  }

  Future<int> sendBuzzMsg(BuzzMsg msg) async {
    String smsg = msg.toSocketMsg();
    return await send(smsg);
  }
}

class ServerMulticastListener {
  final Endpoint multicastEndpoint = Endpoint.multicast(
      InternetAddress(CONST.serverMulticastIP),
      port: Port(CONST.serverMulticastPort));
  late UDP receiver;

  void listen(Function(String) callback) async {
    receiver = await UDP.bind(multicastEndpoint);
    receiver.asStream().listen((Datagram? d) {
      if (d != null) {
        var str = String.fromCharCodes(d.data);

        Log.log('Received multicast: $str');
        callback(str);
      }
    });
  }

  void close() {
    try {
      receiver.close();
    } catch (e) {
      Log.log("Multicast close error");
    }
  }
}

// Client use this to receive messages.
class ServerMulticastListenerNew {
  static String serverData = "";
  static late UDP receiver;
  static DateTime lastUpdateTime = DateTime.now();

  static init() async {
    final Endpoint multicastEndpoint = Endpoint.multicast(
        InternetAddress(CONST.serverMulticastIP),
        port: Port(CONST.serverMulticastPort));

    receiver = await UDP.bind(multicastEndpoint);
    receiver.asStream().listen((Datagram? d) {
      if (d != null) {
        var str = String.fromCharCodes(d.data);

        Log.log('Received multicastNew: $str');
        lastUpdateTime = DateTime.now();
        serverData = str;
      }
    });
  }

  static exit() {
    try {
      receiver.close();
    } catch (e) {
      Log.log("MulticastNew close error");
    }
  }
}
