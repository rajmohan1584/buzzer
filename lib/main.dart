import 'dart:async';
import 'dart:io';
import 'package:buzzer/home.dart';
import 'package:buzzer/model/constants.dart';
import 'package:buzzer/net/util.dart';
import 'package:buzzer/util/log.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'model/game_cache.dart';
import 'net/single_multicast.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GameCache.init();

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  CONST.appVersion = packageInfo.version;

  if (Platform.isWindows) {
    await NUTIL.logInfo();
    CONST.myIP = await NUTIL.myIP();
    CONST.myWifi = await NUTIL.myWifi();
  }

  bool has = GameCache.hasCache();

  if (has) {
    Log.log("Found Game Cache");
  } else {
    Log.log("No Game Cache Found");
  }

  await GameCache.clear();

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
    return MaterialApp(
      theme: ThemeData.dark(),
      darkTheme: ThemeData.dark(),
      home: const Home(),
    );
  }
}
