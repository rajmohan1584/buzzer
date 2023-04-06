import 'dart:io';
//import 'dart:convert';

import 'package:buzzer/model/message.dart';
import 'package:buzzer/model/constants.dart';
import 'package:buzzer/util/log.dart';
import 'package:udp/udp.dart';

//////////////////////////////////////////////////////
// Server uses this to send messages to Clients
// To serverMulticastIP:serverMulticastPort
//
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

//////////////////////////////////////////////////////
// Client use this to receive messages from server
// from serverMulticastIP:serverMulticastPort
//
class ClientMulticastListener {
  final Endpoint multicastEndpoint = Endpoint.multicast(
      InternetAddress(CONST.serverMulticastIP),
      port: Port(CONST.serverMulticastPort));
  late UDP receiver;

  void listen(Function(BuzzMsg) callback) async {
    receiver = await UDP.bind(multicastEndpoint);
    receiver.asStream().listen((Datagram? d) {
      if (d != null) {
        var str = String.fromCharCodes(d.data);
        Log.log('Received multicast: $str');
        final BuzzMsg? msg = BuzzMsg.fromMulticastMessage(str);
        if (msg != null) {
          callback(msg);
        }
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

//////////////////////////////////////////////////////
// Client use this to send messages to server
// To clientMulticastIP:clientMulticastPort
//
class ClientMulticastSender {
  final Endpoint multicastEndpoint = Endpoint.multicast(
      InternetAddress(CONST.clientMulticastIP),
      port: Port(CONST.clientMulticastPort));
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

//////////////////////////////////////////////////////
// Server use this to receive messages frpm client
// From clientMulticastIP:clientMulticastPort
//
class ServertMulticastListener {
  final Endpoint multicastEndpoint = Endpoint.multicast(
      InternetAddress(CONST.clientMulticastIP),
      port: Port(CONST.serverMulticastPort));
  late UDP receiver;

  void listen(Function(BuzzMsg) callback) async {
    receiver = await UDP.bind(multicastEndpoint);
    receiver.asStream().listen((Datagram? d) {
      if (d != null) {
        final str = String.fromCharCodes(d.data);
        Log.log('Received multicast: $str');
        final BuzzMsg? msg = BuzzMsg.fromMulticastMessage(str);
        if (msg != null) {
          callback(msg);
        }
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
