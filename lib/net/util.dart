import 'dart:io';
import 'package:buzzer/util/log.dart';
import 'package:network_info_plus/network_info_plus.dart';

final _networkInfo = NetworkInfo();

class NUTIL {
  static Future printIps() async {
    for (var interface in await NetworkInterface.list()) {
      Log.log('== Interface: ${interface.name} ==');
      for (var addr in interface.addresses) {
        Log.log(
            '${addr.address} ${addr.host} ${addr.isLoopback} ${addr.rawAddress} ${addr.type.name}');
      }
    }
  }

  static Future<String> myIP() async {
    String wifiIPv4 = await _networkInfo.getWifiIP() ?? "";
    Log.log('wifiIPv4: $wifiIPv4');
    return wifiIPv4;
  }

  static Future<String> myWifi() async {
    String wifiName = await _networkInfo.getWifiName() ?? "";
    Log.log('myWifi: $wifiName');
    return wifiName;
  }

  static Future logInfo() async {
    await printIps();
    await myIP();
    await myWifi();
  }
}
