import 'dart:io';

import '../util/log.dart';

class BuzzConnection {
  final String user;
  final Socket socket;

  BuzzConnection(this.user, this.socket);
}

class BuzzConnections {
  final List<BuzzConnection> connections = [];

  BuzzConnection? findByUser(String user) {
    final index = connections.indexWhere((c) => c.user == user);
    if (index == -1) return null;
    return connections[index];
  }

  BuzzConnection? findBySocket(Socket socket) {
    final index = connections.indexWhere((c) => c.socket == socket);
    if (index == -1) return null;
    return connections[index];
  }

  BuzzConnection? add(String user, Socket socket) {
    if (findByUser(user) != null) {
      Log.log('Duplicate name $user');
      return null;
    }
    if (findBySocket(socket) != null) {
      Log.log('Duplicate name $socket');
      return null;
    }

    final conn = BuzzConnection(user, socket);
    connections.add(conn);

    return conn;
  }
}
