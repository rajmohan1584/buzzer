//import 'dart:io';
import 'package:buzzer/model/message.dart';
import 'package:buzzer/util/buzz_state.dart';
import 'package:buzzer/model/defs.dart';

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

  final BuzzMap data;
  BuzzClient(this.data);

  // These "!" will crash if null. Watch out
  String get id => data[BuzzDef.id]!;
  String get name => data[BuzzDef.name]!;
  int get score => data[BuzzDef.score]!;

  void setName(String name) => data[BuzzDef.name] = name;
  void setNameUtf8(StringUtf8 nameUtf8) => data[BuzzDef.nameUtf8] = nameUtf8;
  void setAvatar(int avatar) => data[BuzzDef.avatar] = avatar;

  void setScore(int score) => data[BuzzDef.score] = score;

  performHealthCheck() {
    Duration d = DateTime.now().difference(updated);
    alive = d.inSeconds <= 3;
  }
}

