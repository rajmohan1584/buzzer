//import 'dart:io';
import 'package:buzzer/model/message.dart';
import 'package:buzzer/util/buzz_state.dart';
import 'package:buzzer/model/command.dart';
import 'package:buzzer/util/log.dart';
import 'package:socket_io/socket_io.dart';

class BuzzClient {
  String user;
  bool iAmReady = false;
  String buzzedState = "";
  int score = 0;
  final Socket socket;
  bool bellRinging = false;
  bool bellFlashing = false;
  DateTime created = DateTime.now();
  DateTime updated = DateTime.now();
  BuzzState state = BuzzState.clientWaitingToJoin;
  BuzzMsg? serverMsg;
  BuzzClient(this.user, this.socket);

  void sendMessage(BuzzMsg msg) {
    String s = msg.toSocketMsg();
    Log.log("sendMessage: $s");
    //socket.write(s);
    //List<int> list = utf8.encode(s);
    //Uint8List bytes = Uint8List.fromList(list);
    socket.emit('msg', [s]);
  }
}

class BuzzClients {
  final List<BuzzClient> clients = [];

  int get length => clients.length;

//  (int total, int yes, int no, int pending) get counts {
  List<int> get counts {
    final int total = clients.length;
    int yes = 0, no = 0, pending = 0;
    for (var c in clients) {
      if (c.buzzedState == BuzzCmd.buzzYes) {
        yes++;
      } else if (c.buzzedState == BuzzCmd.buzzNo) {
        no++;
      } else {
        pending++;
      }
    }

    return [total, yes, no, pending];
  }

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

  void sortByReadyUpdated() {
    clients.sort((a, b) {
      if (!a.iAmReady && !b.iAmReady) {
        // both are waiting.
        // order by updated DESC
        return b.updated.compareTo(a.updated);
      }
      if (a.iAmReady && b.iAmReady) {
        // both are waiting.
        // order by updated ASC
        return a.updated.compareTo(b.updated);
      }

      if (a.iAmReady) return -1;
      return 1;
    });
  }

  void sortByBuzzedUpdated() {
    clients.sort((a, b) {
      if (a.buzzedState == BuzzCmd.buzzYes &&
          b.buzzedState == BuzzCmd.buzzYes) {
        // both buzzed YES.
        // order by updated ASC
        return a.updated.compareTo(b.updated);
      }

      if (a.buzzedState == BuzzCmd.buzzYes) return -1;
      if (b.buzzedState == BuzzCmd.buzzYes) return 1;

      if (a.buzzedState.isEmpty && b.buzzedState.isEmpty) {
        // both have not replied - keep in middle.
        // order by updated ASC
        return a.updated.compareTo(b.updated);
      }

      if (a.buzzedState.isEmpty) return -1;
      if (b.buzzedState.isEmpty) return 1;

      // Both buzzed NO
      return a.updated.compareTo(b.updated);
    });
  }

  getTopBuzzedData(int max) {
    final buzzed = [];
    int i = 0;
    for (var client in clients) {
      if (client.buzzedState == BuzzCmd.buzzYes) {
        i++;
        buzzed.add({"position": i, "name": client.user});
        if (i == max) break;
      }
    }
    final data = {"count": i, "buzzers": buzzed};
    return data;
  }
}
