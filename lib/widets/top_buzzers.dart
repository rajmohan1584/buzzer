import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

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
    return const Placeholder();
  }

  Widget buildBody() {
    return Card(
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
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text("$position"), Text(name)],
    ));
  }
}
