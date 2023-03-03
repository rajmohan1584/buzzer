import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'package:buzzer/client/client.dart';
import 'package:buzzer/score_board/score_board.dart';
import 'package:buzzer/server/server.dart';
import 'package:buzzer/util/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  /*
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .catchError((e) {
    NLog.log(" Error : ${e.toString()}");
  });
  */
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(500, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      //titleBarStyle: TitleBarStyle.hidden,
    );

    // Use it only after calling `hiddenWindowAtLaunch`
    windowManager.waitUntilReadyToShow(windowOptions).then((_) async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

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
        title: WIDGETS.appBarTitle(),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            WIDGETS.clientButton(_onClient),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: _onScoreBoard, child: const Text("Score Board")),
            const SizedBox(
              height: 20,
            ),
            WIDGETS.serverButton(_onServer)
          ],
        ),
      ),
    );
  }

  void _onClient() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const BuzzClientScreen()));
  }

  void _onScoreBoard() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const BuzzScoreBoardScreen()));
  }

  void _onServer() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const BuzzServerScreen()));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
