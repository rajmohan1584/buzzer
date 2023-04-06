import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _app = "app";
const _version = "version";
const _clients = "clients";

const _score = "score";

class GameCache {
  //////////////////////////////////////////////////////////////////////
  // hasCache
  //
  static Future<bool> hasCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sClients = prefs.getString(_clients);
    if (sClients == null) {
      return false;
    }
    return true;
  }

  //////////////////////////////////////////////////////////////////////
  // Get Set clients
  //
  static Future<List<String>> getClients() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sClients = prefs.getString(_clients);
    if (sClients != null) {
      // clients is a csv
      return sClients.split(",");
    }
    return [];
  }

  static setClients(List<String> clients) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String sClients = clients.join(",");
    await prefs.setString(_clients, sClients);
  }

  //////////////////////////////////////////////////////////////////////
  // Add Remove client
  //
  static addClient(String id) async {
    List<String> clients = await getClients();
    if (clients.contains(id)) {
      // already exists
      return;
    }

    clients.add(id);
    await setClients(clients);
  }

  static removeClient(id) async {
    List<String> clients = await getClients();
    if (!clients.contains(id)) {
      // client does exists - Probably New
      return;
    }

    clients.remove(id);
    await setClients(clients);
  }

  //////////////////////////////////////////////////////////////////////
  // Set Get Client
  //
  static Future<Map<String, dynamic>?> getClient(String id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sClient = prefs.getString(id);
    if (sClient == null) {
      return null;
    }

    Map<String, dynamic> client = json.decode(sClient);
    return client;
  }

  static Future<bool> setClient(String id, Map<String, dynamic> client) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String sClient = json.encode(client);
    await prefs.setString(id, sClient);
    return true;
  }

  //////////////////////////////////////////////////////////////////////
  // Set Get Client
  //
  static Future<bool> setScore(String id, int score) async {
    Map<String, dynamic>? client = await getClient(id);
    if (client == null) {
      return false;
    }

    client[_score] = score;
    await setClient(id, client);
    return true;
  }
}
