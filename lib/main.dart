import 'package:buzzer/client/client.dart';
import 'package:buzzer/server/server.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() {
    return MyHomePageState();
  }
}

class MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BUZZER"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(onPressed: _onClient, child: const Text("Client")),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(onPressed: _onServer, child: const Text("Server"))
          ],
        ),
      ),
    );
  }

  void _onClient() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const BuzzClient()));
  }

  void _onServer() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const BuzzServer()));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
