import 'package:buzzer/model/constants.dart';
import 'package:flutter/material.dart';

class UserNameInput extends StatefulWidget {
  UserNameInput(this.userName, this.controller, this.w, {Key? key})
      : super(key: key);
  final String userName;
  final double w;
  final TextEditingController controller;

  @override
  State<UserNameInput> createState() => _UserNameInputState();
}

class _UserNameInputState extends State<UserNameInput> {
  @override
  Widget build(BuildContext context) {
    return buildInput();
  }

  Widget buildInput() {
    return SizedBox(
      width: widget.w / 1.5,
      height: 50,
      child: TextField(
          textAlign: TextAlign.center,
          maxLength: 25,
          decoration: const InputDecoration(
              hintText: "உ ன்   பெ ய ர்",
              hintStyle: TextStyle(color: Colors.blueGrey)),
          //focusNode: focusNode,
          autofocus: true,
          enableSuggestions: false,
          autocorrect: false,
          keyboardType: TextInputType.name,
          controller: widget.controller,
          //onChanged: onClientNameChanged,
          style: TextStyle(fontSize: 32, color: CONST.textColor)),
    );
  }
}
