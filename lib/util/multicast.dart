import 'dart:io';
import 'dart:convert';

import 'package:buzzer/util/constants.dart';
import 'package:buzzer/util/log.dart';

class MulticastBroadcast {
  Future<RawDatagramSocket> socket =
      RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

  void broadcast(String msg) {
    Log.log('Sending multicast message: $msg');
    socket.then((socket) {
      socket.send(utf8.encode(msg), InternetAddress(CONST.multicastIP),
          CONST.multicastPort);
    });
  }
}

class MulticastListen {
  Future<RawDatagramSocket> socket =
      RawDatagramSocket.bind(InternetAddress.anyIPv4, CONST.multicastPort);

  void listen(Function(String) callback) {
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
}

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