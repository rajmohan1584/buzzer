import 'dart:convert';

import 'package:buzzer/model/game_cache.dart';

class ServerSettings {
  String viewMode = "grid"; // "list"
  bool enableTimeout = true; // Round timeout
  int timeoutSeconds = 10;
  bool enableBuzzed = true;
  int buzzedCount = 3; // Stop round after this buzzes

  ServerSettings(
      {this.viewMode = "grid",
      this.enableTimeout = true,
      this.timeoutSeconds = 10,
      this.enableBuzzed = true,
      this.buzzedCount = 3});

  void updateFromJson(Map<String, dynamic> json) {
    if (json['viewMode'] != null) {
      viewMode = json['viewMode'];
    }
    if (json['enableTimeout'] != null) {
      enableTimeout = json['enableTimeout'];
    }
    if (json['timeoutSeconds'] != null) {
      timeoutSeconds = json['timeoutSeconds'];
    }
    if (json['enableBuzzed'] != null) {
      enableBuzzed = json['enableBuzzed'];
    }
    if (json['buzzedCount'] != null) {
      buzzedCount = json['buzzedCount'];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'viewMode': viewMode,
      'enableTimeout': enableTimeout,
      'timeoutSeconds': timeoutSeconds,
      'enableBuzzed': enableBuzzed,
      'buzzedCount': buzzedCount,
    };
  }

  void saveInCache() async {
    String s = jsonEncode(toJson());
    await GameCache.setString("serverSettings", s);
  }

  void loadFromCache() {
    String s = GameCache.getString("serverSettings");
    if (s.isEmpty) return;

    Map<String, dynamic> map = jsonDecode(s);
    updateFromJson(map);
  }
}
