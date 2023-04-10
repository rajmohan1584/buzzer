// Import the test package and Counter class
import 'package:buzzer/model/game_cache.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test('Counter value should be incremented', () async {
    bool has = GameCache.hasCache();

    expect(has, false);
  });
}
