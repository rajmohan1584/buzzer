import 'dart:convert';
import 'dart:typed_data';

//enum BuzzCmd { login="LOGIN", logout }

class BuzzMsg {
  static final command = [];
  String source;
  String cmd;
  Map<String, dynamic> data;
  BuzzMsg(this.source, this.cmd, this.data);

  String toSocketMsg() {
    String jsonData = json.encode(data);
    String msg = '$source~$cmd~$jsonData';
    return msg;
  }

  static BuzzMsg? fromSocketMsg(Uint8List rawData) {
    final msg = String.fromCharCodes(rawData);
    if (msg.isEmpty) return null;
    final List<String> a = msg.split('~');
    if (a.length < 3) return null;

    String source = a[0];
    String cmd = a[1];
    Map<String, dynamic> data = json.decode(a[2]);

    return BuzzMsg(source, cmd, data);
  }
}
