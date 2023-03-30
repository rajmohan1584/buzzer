import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  onLogin() {}
  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    if (w > MediaQuery.of(context).size.height) {
      w = MediaQuery.of(context).size.height;
    }
    w -= 20;
    return Scaffold(
        appBar: AppBar(title: const Text("Buzzer - Waiting for Quiz Master")),
        backgroundColor: Colors.black,
        floatingActionButton: FloatingActionButton.extended(
            onPressed: onLogin, label: const Text("Login as Quiz Master")),
        body: Center(
            child: SizedBox(width: w, height: w, child: WIDGETS.buildRadar())));
  }
}
