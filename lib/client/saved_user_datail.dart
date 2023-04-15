import 'package:buzzer/model/defs.dart';
import 'package:buzzer/model/game_cache.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';

class SavedUserDetail extends StatefulWidget {
  const SavedUserDetail({Key? key}) : super(key: key);

  @override
  State<SavedUserDetail> createState() => _SavedUserDetailState();
}

class _SavedUserDetailState extends State<SavedUserDetail> {
  late BuzzMap? savedUser;

  @override
  void initState() {
    loadCache();
    super.initState();
  }

  loadCache() {
    savedUser = GameCache.getSavedClientFromCache();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      //leading: WIDGETS.heartbeatIcon(alive),
      title: WIDGETS.appBarTitle(name: "Data"),
    );

    return Scaffold(
      appBar: appBar,
      body: buildBody(),
    );
  }

  Widget buildBody() {
    return Padding(padding: const EdgeInsets.all(8.0), child: buildDetail());
  }

  Widget buildDetail() {
    String id = savedUser?[BuzzDef.id] ?? "null";
    String name = savedUser?[BuzzDef.name] ?? "null";
    int avatar = savedUser?[BuzzDef.avatar] ?? 0;

    return Column(
      children: [
        const Text("Client Cache"),
        Text("     ${BuzzDef.id}:  $id"),
        Text("     ${BuzzDef.name}:  $name"),
        Text("     ${BuzzDef.avatar}:  $avatar"),
      ],
    );
  }
}
