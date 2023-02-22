/*
import 'package:flutter/material.dart';
import 'package:buzzer/model/client.dart';

class BuzzClients2 extends StatefulWidget {
  const BuzzClients2({Key? key}) : super(key: key);

  @override
  State<BuzzClients2> createState() => _BuzzClients2State();
}

class _BuzzClients2State extends State<BuzzClients2> {
  final BuzzClients2 clients = const BuzzClients2();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: clients. .length,
      itemBuilder: (context, int index) {
        BuzzClient client = clients.connections[index];
        // todo - call buildServer
        return buildClient(client);
      },
    );
  }

  Widget buildClient(BuzzClient client) {
    return GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => EnvJobDetailScreen(job)));
        },
        child: buildJobCard(context, svr, job, nextJob));
  }

  Widget buildClientCard(BuzzClient client) {}
}
*/
