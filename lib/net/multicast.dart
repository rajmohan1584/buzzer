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
      //reusePort: true,
      //multicastLoopback: true,
    );

    rawSocket.joinMulticast(address);
  }

  Future<int> send(String msg) async {
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

  Future<int> sendBuzzMsg(BuzzMsg msg) async {
    String smsg = msg.toSocketMsg();
    if (msg.cmd != BuzzCmd.hbq) {
      Log.log('ServerMulticastSender Sent sendBuzzMsg: $smsg');
    }
    return await send(smsg);
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
      //reusePort: true,
      //multicastLoopback: true,
    );

    rawSocket.joinMulticast(address);
  }


  Future<int> send(String msg) async {
    try {
      //Log.log('ClientMulticastSender Sending multicast message: $msg');
      int bytes = rawSocket.send(msg.codeUnits, address, port);
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
  var address = InternetAddress(CONST.clientMulticastIP);
  var port = CONST.clientMulticastPort;
  late RawDatagramSocket rawSocket;

  Future init() async {
    rawSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
      //reusePort: true,
      //multicastLoopback: true,
    );

    rawSocket.joinMulticast(address);
  }

  Future listen(Function(BuzzMsg) callback) async {
    rawSocket.listen((event) {
      if (event == RawSocketEvent.read) {
        var datagram = rawSocket.receive();
        if (datagram != null) {
          final str = String.fromCharCodes(datagram.data);
          Log.log('ServertMulticastListener Received: $str');
          final BuzzMsg? msg = BuzzMsg.fromMulticastMessage(str);
          if (msg != null) {
            callback(msg);
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
