import 'package:buzzer/model/defs.dart';
import 'package:buzzer/util/language.dart';

class User {
  final String id;
  final String name;
  final int avatar;

  User(this.id, this.name, this.avatar);

  BuzzMap getMap() {
    return {
      BuzzDef.id: id,
      BuzzDef.name: name,
      BuzzDef.avatar: avatar,
      BuzzDef.nameUtf8: LANG.name2Socket(name)
    };
  }
}
