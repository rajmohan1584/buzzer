import 'package:flutter/material.dart';
import 'package:buzzer/model/connection.dart';

class BuzzClients extends StatefulWidget {
  const BuzzClients({Key? key}) : super(key: key);

  @override
  State<BuzzClients> createState() => _BuzzClientsState();
}

class _BuzzClientsState extends State<BuzzClients> {
  final BuzzConnections clients = BuzzConnections();

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
