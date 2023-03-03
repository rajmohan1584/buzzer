import 'package:network_info_plus/network_info_plus.dart';

final _networkInfo = NetworkInfo();

class NET {
  static Future<String> myIP() async {
    String? wifiIPv4 = await _networkInfo.getWifiIP();
    if (wifiIPv4 != null) return wifiIPv4;
    return "";
  }

  static Future<String> myWifi() async {
    String? wifiName = await _networkInfo.getWifiName();
    if (wifiName != null) return wifiName;
    return "";
  }
}
