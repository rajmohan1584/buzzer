import 'package:buzzer/model/client.dart';
import 'package:buzzer/model/server_settings.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';

class ServerSettingsScreen extends StatefulWidget {
  final ServerSettings settings;

  ServerSettingsScreen(this.settings, {Key? key}) : super(key: key);

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late final ServerSettings settings;

  @override
  void initState() {
    settings = widget.settings;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      //leading: WIDGETS.heartbeatIcon(alive),
      title: WIDGETS.appBarTitle(name: "Settings"),
    );

    return Scaffold(
      appBar: appBar,
      body: buildBody(),
    );
  }

  Widget buildBody() {
    Widget timout = WIDGETS.switchRowWithInput(
        "Auto Stop Timeout Seconds",
        settings.enableTimeout,
        onChangeEnableTimeout,
        settings.timeoutSeconds,
        onTimeoutSecondsChange);

    Widget buzzed = WIDGETS.switchRowWithInput(
        "Auto Stop on தெரியும் Count",
        settings.enableBuzzed,
        onChangeEnableBuzzed,
        settings.buzzedCount,
        onBuzzedCountChange);

    final child = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 5),
          const Divider(height: 2, thickness: 2),
          const SizedBox(height: 5),
          timout,
          buzzed,
          const SizedBox(height: 5),
          const Divider(height: 2, thickness: 2),
        ]);

    return child;
  }

  void onChangeEnableTimeout(bool enable) {
    setState(() {
      settings.enableTimeout = enable;
    });
  }

  void onTimeoutSecondsChange(int timeout) {
    setState(() {
      settings.timeoutSeconds = timeout;
    });
  }

  void onChangeEnableBuzzed(bool enable) {
    setState(() {
      settings.enableBuzzed = enable;
    });
  }

  void onBuzzedCountChange(int count) {
    setState(() {
      settings.buzzedCount = count;
    });
  }
}
