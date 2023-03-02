import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';

class BuzzMsg {
  //static final command = [];
  DateTime ts = DateTime.now();
  String source;
  String cmd;
  Map<String, dynamic> data = {};
  BuzzMsg(this.source, this.cmd, this.data);

  String toSocketMsg() {
    String jsonData = json.encode(data);
    String msg = '$source~$cmd~$jsonData';
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

  static BuzzMsg? fromSocketMsg(Uint8List rawData) {
    final msg = String.fromCharCodes(rawData);
    return fromSocketIOMsg(msg);
  }

  static BuzzMsg? fromSocketIOMsg(String msg) {
    if (msg.isEmpty) return null;
    final List<String> a = msg.split('~');
    if (a.length < 3) return null;

    String source = a[0];
    String cmd = a[1];
    Map<String, dynamic> data = json.decode(a[2]);

    return BuzzMsg(source, cmd, data);
  }
}
