import 'dart:io';

import 'package:buzzer/model/message.dart';
import 'package:buzzer/util/buzz_state.dart';
import 'package:buzzer/util/log.dart';

class BuzzClient {
  String user;
  final Socket socket;
  DateTime created = DateTime.now();
  DateTime updated = DateTime.now();
  BuzzState state = BuzzState.clientWaitingToJoin;
  BuzzMsg? serverMsg;
  BuzzClient(this.user, this.socket);

  void sendMessage(BuzzMsg msg) {
    String s = msg.toSocketMsg();
    Log.log("sendMessage: $s");
    socket.write(s);
  }
}

class BuzzClients {
  final List<BuzzClient> clients = [];

  int get length => clients.length;

  operator [](int i) => clients[i];

  BuzzClient? findByUser(String user) {
    final index = clients.indexWhere((c) => c.user == user);
    if (index == -1) return null;
    return clients[index];
  }

  BuzzClient? findBySocket(Socket socket) {
    final index = clients.indexWhere((c) => c.socket == socket);
    if (index == -1) return null;
    return clients[index];
  }

  int indexOfSocket(Socket socket) {
    for (var i = 0; i < clients.length; i++) {
      if (clients[i].socket == socket) {
        return i;
      }
    }
    return -1;
  }

  BuzzClient? add(String user, Socket socket) {
    if (findByUser(user) != null) {
      Log.log('Duplicate name $user');
      return null;
    }
    if (findBySocket(socket) != null) {
      Log.log('Duplicate name $socket');
      return null;
    }

    final client = BuzzClient(user, socket);
    clients.add(client);

    return client;
  }

  void remove(Socket socket) {
    final index = indexOfSocket(socket);
    if (index < 0) {
      Log.log('Cannot find socket ${socket.toString()}');
      return;
    }

    clients.removeAt(index);
  }
}
