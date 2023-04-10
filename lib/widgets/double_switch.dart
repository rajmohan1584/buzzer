import 'package:flutter/cupertino.dart';

//////////////////
///
class DoubleButtonController extends ChangeNotifier {
  bool _sw1Checked = false;
  bool _sw2Checked = false;
  bool _sw1Enabled = true;
  bool _sw2Enabled = false;

  bool get sw1Checked => _sw1Checked;
  bool get sw2Checked => _sw2Checked;
  bool get sw1Enabled => _sw1Enabled;
  bool get sw2Enabled => _sw2Enabled;

  void reset() {
    _sw1Checked = false;
    _sw2Checked = false;
    _sw2Enabled = false;
  }

  set sw1Checked(bool value) {
    _sw1Checked = value;
    //notifyListeners();
  }

  set sw2Checked(bool value) {
    _sw2Checked = value;
    notifyListeners();
  }

  set sw1Enabled(bool value) {
    _sw1Enabled = value;
    //notifyListeners();
  }

  set sw2Enabled(bool value) {
    _sw2Enabled = value;
    //notifyListeners();
  }
}

class DoubleButton extends StatefulWidget {
  final DoubleButtonController controller;
  const DoubleButton(this.controller, {super.key});

  @override
  State<DoubleButton> createState() => _DoubleButtonState();
}

class _DoubleButtonState extends State<DoubleButton> {
  late final DoubleButtonController controller;

  @override
  void initState() {
    controller = widget.controller;
    super.initState();
  }

  buildControls() {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CupertinoSwitch(
                    value: controller.sw1Checked,
                    onChanged: controller.sw1Enabled ? onSwitch1Changed : null),
                CupertinoSwitch(
                    value: controller.sw2Checked,
                    onChanged: controller.sw2Enabled ? onSwitch2Changed : null),
              ]),
          const Text("Double Button")
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 200, child: buildControls());
  }

  void check() {
    setState(() {
      if (controller.sw1Checked) {
        controller.sw2Enabled = true;
      } else {
        controller.sw2Enabled = false;
        controller.sw2Checked = false;
      }
      if (controller.sw2Checked) {
        controller.sw2Enabled = false;
      }
    });
  }

  void onSwitch1Changed(bool enable) {
    setState(() {
      controller.sw1Checked = enable;
    });
    check();
  }

  void onSwitch2Changed(bool enable) {
    setState(() {
      controller.sw2Checked = enable;
    });
    check();
  }
}
