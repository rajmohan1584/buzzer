import 'package:flutter/material.dart';

class TopBuzzers extends StatefulWidget {
  final List<dynamic> buzzers;
  const TopBuzzers(this.buzzers, {super.key});

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

    return Card(
        margin: const EdgeInsets.fromLTRB(50.0, 5.0, 50.0, 5.0),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("$position"), Text(name)],
          ),
        ));
  }
}
