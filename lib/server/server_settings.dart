import 'package:buzzer/model/server_settings.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ServerSettingsScreen extends StatefulWidget {
  final ServerSettings settings;

  const ServerSettingsScreen(this.settings, {Key? key}) : super(key: key);

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

  onViewModeListChanged(bool on) {
    final viewMode = on ? "list" : "grid";
    setState(() {
      settings.viewMode = viewMode;
    });
  }

  onViewModeGridChanged(bool on) {
    final viewMode = on ? "grid" : "list";
    setState(() {
      settings.viewMode = viewMode;
    });
  }

  onSaveSettings() {
    Navigator.pop(context, settings);
  }

  onCancel() {
    Navigator.pop(context, null);
  }

  Widget buildBody() {
    Widget viewMode = Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.rectangle_grid_1x2, size: 50),
          const Text("Set Display Mode to List"),
          CupertinoSwitch(
              value: settings.viewMode == "list",
              onChanged: onViewModeListChanged),
        ],
      ),
      const SizedBox(height: 15),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.rectangle_grid_3x2, size: 50),
          const Text("Set Display Mode to Grid"),
          CupertinoSwitch(
              value: settings.viewMode == "grid",
              onChanged: onViewModeGridChanged),
        ],
      )
    ]);

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

    Widget actions =
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      WIDGETS.button("Cancel", onCancel),
      const SizedBox(width: 100),
      WIDGETS.button("Save", onSaveSettings)
    ]);

    final child = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 5),
          const Divider(height: 2, thickness: 2),
          const SizedBox(height: 5),
          viewMode,
          const SizedBox(height: 5),
          const Divider(height: 2, thickness: 2),
          const SizedBox(height: 50),
          const Divider(height: 2, thickness: 2),
          const SizedBox(height: 5),
          timout,
          buzzed,
          const SizedBox(height: 5),
          const Divider(height: 2, thickness: 2),
          const SizedBox(height: 50),
          actions
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
