import 'dart:io';
//import 'dart:convert';

import 'package:buzzer/model/message.dart';
import 'package:buzzer/model/constants.dart';
import 'package:buzzer/util/log.dart';

import '../model/command.dart';

//////////////////////////////////////////////////////
// Server uses this to send messages to Clients
// To serverMulticastIP:serverMulticastPort
//
class ServerMulticastSender {
  var address = InternetAddress(CONST.serverMulticastIP);
  var port = CONST.serverMulticastPort;
  late RawDatagramSocket rawSocket;

  Future init() async {
    rawSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
      reusePort: true,
      //multicastLoopback: true,
    );

    rawSocket.joinMulticast(address);
  }

  int send(String msg) {
    try {
      //Log.log('ServerMulticastSender Sending multicast message: $msg');
      int bytes = rawSocket.send(msg.codeUnits, address, port);
      //Log.log('ServerMulticastSender Sent multicast bytes: $bytes');
      return bytes;
    } catch (e) {
      Log.log('Error $e');
      rethrow;
    }
  }

  int sendBuzzMsg(BuzzMsg msg) {
    String smsg = msg.toSocketMsg();
    if (msg.cmd != BuzzCmd.hbq) {
      Log.log('ServerMulticastSender Sent sendBuzzMsg: $smsg');
    }
    return send(smsg);
  }
}



//////////////////////////////////////////////////////
// Client use this to send messages to server
// To clientMulticastIP:clientMulticastPort
//
class ClientMulticastSender {
  var address = InternetAddress(CONST.clientMulticastIP);
  var port = CONST.clientMulticastPort;
  late RawDatagramSocket rawSocket;

  Future init() async {
    rawSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
      reusePort: true,
      //multicastLoopback: true,
    );

    rawSocket.joinMulticast(address);
  }


  int send(String msg) {
    try {
      //Log.log('ClientMulticastSender Sending multicast message: $msg');
      int bytes = rawSocket.send(msg.codeUnits, address, port);
      return bytes;
    } catch (e) {
      Log.log('Error $e');
      rethrow;
    }
  }

  int sendBuzzMsg(BuzzMsg msg) {
    String smsg = msg.toSocketMsg();
    return send(smsg);
  }
}

