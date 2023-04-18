import 'package:buzzer/model/constants.dart';
import 'package:buzzer/util/widgets.dart';
import 'package:flutter/material.dart';

class UserAvatarSelector extends StatelessWidget {
  UserAvatarSelector(this.userAvatar, this.onChanged, this.w, {Key? key})
      : super(key: key);
  int userAvatar;
  double w;
  Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return buildAvatarGrid();
  }

  buildAvatarGrid() {
    final List<Widget> avatars = [];
    for (var i = 1; i <= 6; i++) {
      // TODO - get min max from somewhere
      final color = userAvatar == i ? CONST.textColor : Colors.black;
      avatars.add(GestureDetector(
          onTap: () {
            userAvatar = userAvatar == i ? 0 : i;
            onChanged(userAvatar);
          },
          child: WIDGETS.clientAvatar(i, color)));
    }

    return SizedBox(
        width: w / 2,
        height: 175,
        child: GridView.count(
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            crossAxisCount: 3,
            children: avatars));
  }
}
