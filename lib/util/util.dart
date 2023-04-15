import 'dart:math';

class UTIL {
  static final _random = Random();

  static randomInt({int min = 0, int max = 100}) {
    return _random.nextInt(max - min) + min;
  }
}
