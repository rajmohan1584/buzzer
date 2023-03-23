import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class IntSpinner extends StatefulWidget {
  final int value, min, max;
  final void Function(double p1) onChanged;
  const IntSpinner(this.value, this.min, this.max, this.onChanged, {Key? key})
      : super(key: key);

  @override
  State<IntSpinner> createState() => _IntSpinnerState();
}

class _IntSpinnerState extends State<IntSpinner> {
  TextEditingController intController = TextEditingController();
  late int value, min, max;

  @override
  void initState() {
    super.initState();
    value = widget.value;
    min = widget.min;
    max = widget.max;

    intController.text = '$value';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [buildMinus(), buildInput(), buildPlus()],
    );
  }

  Widget buildInput() {
    return Expanded(
      flex: 1,
      child: TextFormField(
          controller: intController,
          readOnly: true,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
              contentPadding: const EdgeInsets.all(5))),
    );
  }

  setValue(int v) {
    setState(() {
      value = v;
      intController.text = '$value';
      widget.onChanged(v.toDouble());
    });
  }

  Widget buildMinus() {
    return GestureDetector(
        child: const Icon(CupertinoIcons.minus_circled),
        onTap: () => {
              if (value > min) {setValue(value - 1)}
            });
  }

  Widget buildPlus() {
    return GestureDetector(
        child: const Icon(CupertinoIcons.plus_circled),
        onTap: () => {
              if (value < max) {setValue(value + 1)}
            });
  }

  Widget buildSpinner() {
    // Vertical only
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(child: const Icon(Icons.arrow_upward_rounded)),
        GestureDetector(child: const Icon(Icons.arrow_downward_rounded))
      ],
    );
  }
}
