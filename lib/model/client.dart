import 'dart:io';

import '../util/log.dart';

class BuzzClient {
  String user;
  final Socket socket;

  BuzzClient(this.user, this.socket);
}

class BuzzClients {
  final List<BuzzClient> clients = [];

  int get length => clients.length;

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
}
