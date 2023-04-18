import 'package:buzzer/client/avatar_selector.dart';
import 'package:buzzer/client/client_name_input.dart';
import 'package:buzzer/model/defs.dart';
import 'package:buzzer/model/game_cache.dart';
import 'package:buzzer/model/user.dart';
import 'package:buzzer/util/language.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';

class UserClientDetail extends StatefulWidget {
  const UserClientDetail(this.user, {Key? key}) : super(key: key);

  final User user;

  @override
  State<UserClientDetail> createState() => _UserClientDetailState();
}

class _UserClientDetailState extends State<UserClientDetail> {
  late BuzzMap? savedUser;
  late String userId;
  late String userName;
  late int userAvatar;

  final userNameController = TextEditingController();

  @override
  void initState() {
    loadCache();
    userId = widget.user.id;
    userName = widget.user.name;
    userAvatar = widget.user.avatar;

    userNameController.text = userName;

    super.initState();
  }

  loadCache() {
    savedUser = GameCache.getSavedClientFromCache();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      //leading: WIDGETS.heartbeatIcon(alive),
      title: WIDGETS.appBarTitle(name: "Detail"),
    );

    return Scaffold(
      appBar: appBar,
      body: buildBody(),
    );
  }

  onUserAvatarChanged(int avatar) {
    setState(() => userAvatar = avatar);
  }

  onCancel() {
    Navigator.pop(context, null);
  }

  onSave() {
    userName = userNameController.text;
    Navigator.pop(context, User(userId, userName, userAvatar));
  }

  Widget buildBody() {
    return Padding(padding: const EdgeInsets.all(8.0), child: buildDetail());
  }

  Widget buildDetail() {
    double w = MediaQuery.of(context).size.width;
    if (w > MediaQuery.of(context).size.height) {
      w = MediaQuery.of(context).size.height;
    }
    w -= 50;

    Widget actions =
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      WIDGETS.button("Cancel", onCancel),
      const SizedBox(width: 100),
      WIDGETS.button("Save", onSave)
    ]);

    final List<Widget> children = [
      Align(child: WIDGETS.tamilText("தோட்றம் மாற்றம்", 20.0)),
      const Divider(indent: 100.0, endIndent: 100.0, height: 4),
      const SizedBox(height: 25),
      UserAvatarSelector(userAvatar, onUserAvatarChanged, w),
      Align(child: WIDGETS.tamilText("பெயர் மாற்றம்", 20.0)),
      const Divider(indent: 100.0, endIndent: 100.0, height: 4),
      const SizedBox(height: 25),
      UserNameInput(userName, userNameController, w),
      const SizedBox(height: 150),
      actions,
      const SizedBox(height: 25),
      const Divider(height: 2),
      const SizedBox(height: 25)
    ];

    String id = savedUser?[BuzzDef.id] ?? "null";
    int avatar = savedUser?[BuzzDef.avatar] ?? 0;

    String name = savedUser?[BuzzDef.name] ?? "null";
    StringUtf8 nameUtf8 = LANG.parseNameUtf8(savedUser);
    if (nameUtf8.isNotEmpty) name = LANG.socket2Name(nameUtf8);

    children.addAll([
      const Text("Client Cache"),
      Text("     ${BuzzDef.id}:  $id"),
      Text("     ${BuzzDef.name}:  $name"),
      Text("     ${BuzzDef.avatar}:  $avatar"),
    ]);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: children,
    );
  }
}
