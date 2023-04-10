import 'package:buzzer/model/client.dart';
import 'package:buzzer/server/helper.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';

class ClientDetail extends StatefulWidget {
  final BuzzClient client;
  final int index;
  final Function(BuzzClient) sendPingToClient;
  final Function(BuzzClient client, int score) onClientScoreChange;

  const ClientDetail(
      this.client, this.index, this.sendPingToClient, this.onClientScoreChange,
      {Key? key})
      : super(key: key);

  @override
  State<ClientDetail> createState() => _ClientDetailState();
}

class _ClientDetailState extends State<ClientDetail> {
  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      //leading: WIDGETS.heartbeatIcon(alive),
      title: WIDGETS.appBarTitle(name: "நடுவர்"),
    );

    return Scaffold(
      appBar: appBar,
      body: buildBody(),
    );
  }

  Widget buildBody() {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          ServerHelper.buildClient(widget.client, widget.index,
              widget.sendPingToClient, widget.onClientScoreChange),
          const SizedBox(
            height: 30,
          ),
          buildDetail()
        ]));
  }

  Widget buildDetail() {
    return Column(
      children: const [
        Text("TODO"),
        Text("More Client Details"),
        Text("Game status"),
        Text("     Round #1 - Buzzed YES and Answered Correct. +1 points"),
        Text("     Round #2 - Buzzed NO"),
        Text("     Round #3 - NOTA"),
        Text("     Round #4 - Buzzed YES and Answered Wrong"),
      ],
    );
  }
}
