import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';

class TopBuzzers extends StatefulWidget {
  final List<dynamic> buzzers;
  final String myId;
  final String topId;
  const TopBuzzers(this.buzzers, this.myId, this.topId, {super.key});

  @override
  State<TopBuzzers> createState() => _TopBuzzersState();
}

class _TopBuzzersState extends State<TopBuzzers> {
  late final List<dynamic> buzzers;

  @override
  void initState() {
    buzzers = widget.buzzers;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return buildBody();
  }

  Widget buildBody() {
    return Expanded(
        child: ListView.builder(
            itemCount: buzzers.length,
            itemBuilder: (context, int index) {
              Map buzzer = buzzers[index];
              return buildBuzzer(buzzer);
            }));
  }

  Widget buildBuzzer(Map buzzer) {
    final int position = buzzer["position"] ?? -1;
    final String name = buzzer["name"] ?? "Unk";
    final String id = buzzer["id"] ?? "";
    final String buzzedDelta = buzzer["buzzedDelta"] ?? "";

    final children = <Widget>[
      Text(
        "$position",
        style: const TextStyle(fontSize: 30),
      )
    ];

    if (widget.myId == id) {
      Widget you = WIDGETS.assetImage("you.png", width: 75, height: 75);
      children.add(WIDGETS.nameWidget("YOU", you, fontSize: 20.0));
    }

    children.add(Text(name, style: const TextStyle(fontSize: 30.0)));

    Widget value =
        WIDGETS.assetImage("Theriyuma-125.png", width: 55, height: 55);
    children.add(WIDGETS.nameWidget(buzzedDelta, value, fontSize: 20.0));

    return Card(
        margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: children,
          ),
        ));
  }
}
