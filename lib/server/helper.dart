import 'package:buzzer/model/client.dart';
import 'package:buzzer/model/constants.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:buzzer/widgets/int_spinner.dart';
import 'package:flutter/material.dart';

class ServerHelper {
  static Widget buildClient(
      BuzzClient client,
      int index,
      Function(BuzzClient)? sendPingToClient,
      Function(BuzzClient client, int score)? onClientScoreChange) {
    /*
    Color color = COLORS.background["gray"]!;
    if (client.iAmReady) {
      color = COLORS.background["green"]!;
    } else {
      color = COLORS.background["yellow"]!;
    }
    */

    final name = Text(client.name,
        style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold));

    Widget row =
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(
          flex: 1,
          child: WIDGETS.bellIconButton(() => sendPingToClient!(client),
              hShake: client.bellRinging, vShake: client.bellFlashing)),
      Expanded(flex: 5, child: name),
      //Expanded(child: WIDGETS.nameValue('port', '${client.socket.remotePort}')),
      Expanded(flex: 2, child: WIDGETS.buzzedStatus(client.buzzedState, index)),
      Expanded(
          flex: 3,
          child: IntSpinner(
              client.score,
              CONST.clientMinScore,
              CONST.clientMaxScore,
              (int v) => {onClientScoreChange!(client, v)})),
    ]);

    final Color color = client.alive ? Colors.greenAccent : Colors.redAccent;

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
        elevation: 10.0,
        shape: Border(left: BorderSide(color: color, width: 5)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: row,
        ));
  }
}
