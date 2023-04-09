import 'package:buzzer/model/client.dart';
import 'package:buzzer/server/helper.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';

class ClientDetail extends StatefulWidget {
  BuzzClient client;
  int index;
  ClientDetail(this.client, this.index, {Key? key}) : super(key: key);

  @override
  State<ClientDetail> createState() => _ClientDetailState();
}

class _ClientDetailState extends State<ClientDetail> {
  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      //leading: WIDGETS.heartbeatIcon(alive),
      title: WIDGETS.appBarTitle(name: widget.client.name),
    );

    return Scaffold(
      appBar: appBar,
      body: buildBody(),
    );
  }

  Widget buildBody() {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child:
            ServerHelper.buildClient(widget.client, widget.index, null, null));
  }
}
