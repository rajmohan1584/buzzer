import 'dart:async';
import 'dart:io';
import 'package:buzzer/home.dart';
import 'package:buzzer/model/constants.dart';
import 'package:buzzer/util/log.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'package:buzzer/client/client.dart';
//import 'package:buzzer/score_board/score_board.dart';
import 'package:buzzer/server/server.dart';
import 'package:buzzer/util/widgets.dart';

import 'model/game_cache.dart';
import 'net/single_multicast.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GameCache.init();

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  CONST.appVersion = packageInfo.version;

  bool has = GameCache.hasCache();

  if (has) {
    Log.log("Found Game Cache");
  } else {
    Log.log("No Game Cache Found");
  }

  await GameCache.clear();

  /*
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .catchError((e) {
    NLog.log(" Error : ${e.toString()}");
  });
  */
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(500, 850),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    // Use it only after calling `hiddenWindowAtLaunch`
    windowManager.waitUntilReadyToShow(windowOptions).then((_) async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  StaticSingleMultiCast.initListener();

  runZonedGuarded(() {
    runApp(const MyApp());
  }, (Object error, StackTrace stack) {
    Log.log(error);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
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
            WIDGETS.serverButton(_onServer)
          ],
        ),
      ),
    );
  }

  void _onClient() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const BuzzClientScreen()));
  }

  /*
  void _onScoreBoard() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const BuzzScoreBoardScreen()));
  }
  */

  void _onServer() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const BuzzServerScreen()));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
