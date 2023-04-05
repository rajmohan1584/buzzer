import 'dart:io';
//import 'dart:convert';

import 'package:buzzer/util/constants.dart';
import 'package:buzzer/util/log.dart';
import 'package:udp/udp.dart';

class MulticastSender {
  final Endpoint multicastEndpoint = Endpoint.multicast(
      InternetAddress(CONST.multicastIP),
      port: Port(CONST.multicastPort));
  late UDP sender;

  Future init() async {
    sender = await UDP.bind(Endpoint.any());
  }

  Future<int> broadcast(String msg) async {
    try {
      Log.log('Sending multicast message: $msg');
      int bytes = await sender.send(msg.codeUnits, multicastEndpoint);
      Log.log('Sent multicast bytes: $bytes');
      return bytes;
    } catch (e) {
      Log.log('Error $e');
      rethrow;
    }
  }
}

class MulticastListener {
  final Endpoint multicastEndpoint = Endpoint.multicast(
      InternetAddress(CONST.multicastIP),
      port: Port(CONST.multicastPort));
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

class MulticastListenerNew {
  static String serverData = "";
  static late UDP receiver;
  static DateTime lastUpdateTime = DateTime.now();

  static init() async {
    final Endpoint multicastEndpoint = Endpoint.multicast(
        InternetAddress(CONST.multicastIP),
        port: Port(CONST.multicastPort));

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

/*
class MulticastBroadcast {
  Future<RawDatagramSocket> socket =
      RawDatagramSocket.bind(InternetAddress.anyIPv4, 0, ttl: 3);

  void broadcast(String msg) {
    Log.log('Sending multicast message: $msg');
    socket.then((socket) {
      socket.send('$msg\n'.codeUnits, InternetAddress(CONST.multicastIP),
          CONST.multicastPort);
    });
  }
}

class MulticastListen {
  Future<RawDatagramSocket> socket =
      RawDatagramSocket.bind(InternetAddress.anyIPv4, CONST.multicastPort);

  void listen(Function(String) callback) {
    Log.log('MulticastListen.listen');
    socket.then((socket) {
      Log.log('MulticastListen.listen socket.then - JoinMulticast');
      socket.joinMulticast(InternetAddress(CONST.multicastIP));
      Log.log('MulticastListen.listen Actually listening');
      socket.listen((event) {
        Log.log('MulticastListen.listen event $event');
        Datagram? d = socket.receive();
        if (d != null) {
          var message = String.fromCharCodes(d.data).trim();
          Log.log('Datagram from ${d.address.address}:${d.port}: $message');
          callback(message);
        }
      });
    });
  }
}
*/
  /*
  static void sendMulticast(String message) {
    Log.log('Sending multicast message: $message');
    var socket =
        RawDatagramSocket.bind(InternetAddress.anyIPv4, CONST.multicastPort);
    socket.then((socket) {
      socket.send(utf8.encode(message), InternetAddress(CONST.multicastIP),
          CONST.multicastPort);
      socket.close();
    });
  }

  static void listenMulticast(Function(String) callback) {
    var socket =
        RawDatagramSocket.bind(InternetAddress.anyIPv4, CONST.multicastPort);
    socket.then((socket) {
      socket.joinMulticast(InternetAddress(CONST.multicastIP));
      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          var datagram = socket.receive();
          if (datagram != null) {
            var message = utf8.decode(datagram.data);
            Log.log('Received multicast message: $message');
            callback(message);
          }
        }
      });
    });
  }
  */