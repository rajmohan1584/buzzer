//import 'dart:io';
import 'package:buzzer/model/message.dart';
import 'package:buzzer/util/buzz_state.dart';
import 'package:buzzer/model/defs.dart';
import 'package:buzzer/util/format.dart';
import 'package:buzzer/util/language.dart';
import 'package:buzzer/util/log.dart';

class BuzzClient {
  bool iAmReady = false;
  String buzzedState = "";
  bool bellRinging = false;
  bool bellFlashing = false;
  DateTime created = DateTime.now();
  DateTime updated = DateTime.now();
  Duration? buzzedYesDelta;
  BuzzState state = BuzzState.clientWaitingToJoin;
  BuzzMsg? serverMsg;
  bool alive = true;

  // These "!" will crash if null. Watch out
  String get id => data[BuzzDef.id]!;
  String get name => data[BuzzDef.name]!;
  int get score => data[BuzzDef.score]!;

  void setName(String name) => data[BuzzDef.name] = name;
  void setNameUtf8(StringUtf8 nameUtf8) => data[BuzzDef.nameUtf8] = nameUtf8;
  void setAvatar(int avatar) => data[BuzzDef.avatar] = avatar;

  void setScore(int score) => data[BuzzDef.score] = score;

  final BuzzMap data;
  BuzzClient(this.data);

  performHealthCheck() {
    Duration d = DateTime.now().difference(updated);
    alive = d.inSeconds <= 3;
  }
}

class BuzzClients {
  final List<BuzzClient> clients = [];

  int get length => clients.length;

//  (int total, int yes, int no, int nota) get counts {
  List<int> get counts {
    final int total = clients.length;
    int alive = 0, dead = 0, yes = 0, no = 0, nota = 0;
    for (var c in clients) {
      if (c.alive) {
        alive++;
      } else {
        dead++;
      }

      if (c.buzzedState == BuzzDef.buzzYes) {
        yes++;
      } else if (c.buzzedState == BuzzDef.buzzNo) {
        no++;
      } else {
        nota++;
      }
    }

    return [total, alive, dead, yes, no, nota];
  }

  operator [](int i) => clients[i];

  BuzzClient? findById(String id) {
    final index = clients.indexWhere((c) => c.id == id);
    if (index == -1) return null;
    return clients[index];
  }

  int indexOfClient(String id) {
    for (var i = 0; i < clients.length; i++) {
      if (clients[i].id == id) {
        return i;
      }
    }
    return -1;
  }

  performHealthCheck() {
    for (var c in clients) {
      c.performHealthCheck();
    }
  }

  BuzzClient? add(BuzzMap data) {
    String id = data[BuzzDef.id];
    if (findById(id) != null) {
      Log.log('Duplicate name $id');
      return null;
    }

    final client = BuzzClient(data);
    clients.add(client);

    return client;
  }

  void remove(String id) {
    final index = indexOfClient(id);
    if (index < 0) {
      Log.log('Cannot find id $id');
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
      if (a.buzzedState == BuzzDef.buzzYes &&
          b.buzzedState == BuzzDef.buzzYes) {
        // both buzzed YES.
        // order by updated ASC
        return a.updated.compareTo(b.updated);
      }

      if (a.buzzedState == BuzzDef.buzzYes) return -1;
      if (b.buzzedState == BuzzDef.buzzYes) return 1;

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
    String topId = "";
    for (var client in clients) {
      if (client.buzzedState == BuzzDef.buzzYes) {
        i++;
        if (topId.isEmpty) {
          topId = client.id;
        }

        final buzzedDelta = FMT.buzzedDelta(client.buzzedYesDelta);

        buzzed.add({
          BuzzDef.position: i,
          BuzzDef.id: client.id,
          BuzzDef.buzzedDelta: buzzedDelta,
          BuzzDef.name: client.name,
          BuzzDef.nameUtf8: LANG.name2Socket(client.name)
        });
        if (i == max) break;
      }
    }
    final data = {"count": i, "topId": topId, "buzzers": buzzed};
    return data;
  }
}
