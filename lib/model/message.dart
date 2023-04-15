import 'dart:convert';
import 'package:buzzer/model/defs.dart';
import 'package:buzzer/util/log.dart';
import 'package:intl/intl.dart';

class BuzzMsg {
  //static final command = [];
  DateTime ts = DateTime.now();

  // S for server, C for client
  String source;

  String cmd;

  // The id of the client who is sending the message.
  // "" if server is the source
  String sourceId;

  // Server can target a message to a client.
  // ALL for all clients.
  // "" if server is the target
  String targetId;

  BuzzMap data = {};
  BuzzMsg(this.source, this.cmd, this.data,
      {this.sourceId = "", this.targetId = ""}) {
    if (source == BuzzDef.server) {
      assert(sourceId.isEmpty);
      assert(targetId.isNotEmpty);
    } else if (source == BuzzDef.client) {
      assert(sourceId.isNotEmpty);
      assert(targetId.isEmpty);
    } else {
      assert(false);
    }
  }

  String toSocketMsg() {
    String jsonData = json.encode(data);
    String msg = '$source~$cmd~$sourceId~$targetId~$jsonData';
    return msg;
  }

  @override
  String toString() {
    final DateFormat fmt = DateFormat('Hms');
    String jsonData = json.encode(data);
    String time = fmt.format(ts);
    String msg = '$time> Source:$source, Cmd:$cmd, Data:$jsonData';
    return msg;
  }

  static BuzzMsg? fromString(String msg) {
    if (msg.isEmpty) return null;
    final List<String?> a = msg.split('~');
    if (a.length < 5) {
      //assert(false);
      Log.log('***** ERROR ***** - fromString - TODO DEbug');
      return null;
    }

    String source = a[0]!;
    String cmd = a[1]!;
    String sourceId = a[2] ?? "";
    String targetId = a[3] ?? "";
    BuzzMap data = json.decode(a[4]!);

    return BuzzMsg(source, cmd, data, sourceId: sourceId, targetId: targetId);
  }
}
