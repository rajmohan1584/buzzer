import 'dart:convert';
import 'package:nanoid/non_secure.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/log.dart';

const _app = "app";
const _version = "version";
const _clients = "clients";

const _name = "name";
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
  // hasCache
  //
  static void dump() async {
    final List<String> clients = await getClients();
    // No Game Cache.
    Log.log("GameDump> Game Cache has `${clients.length} clients.");

    for (var cid in clients) {
      final Map<String, dynamic>? client = await getClient(cid);

      if (client == null) {
        // Bug. Did not cleanup?
        assert(false);
      } else {
        Log.log('$cid - ${client.toString()}');
      }
    }
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
  static Future<String> addNewClient(String name) async {
    //
    // There is nothing to check.
    // Two clients can be with the same name
    // Also if a disconnected client comes in as a new one,
    //    the score will be set to zero and the old connection will be stale.
    //    And the stale connection should be purged later - // TODO
    //

    // Create a new id
    String id = nanoid();

    // Add the id to the array of client ids.
    List<String> clients = await getClients();
    clients.add(id);
    await setClients(clients);

    // Also create a new key with id and the {}
    assert(await getClient(id) == null);
    Map<String, dynamic> client = {};
    client[_name] = name;
    setClient(id, client);

    return id;
  }

  static addRejoinClient(String id, String name) async {
    //
    // A client who was previously connected exited and is rejoining.
    // We need to give him back his score.
    //
    // We may not have to do anything with the cache.
    // THe cache for this client should exist
    // And on the UI, this client would be displayed in stale mode.
    //
    // We just need to activate him?
    //

    if (await getClient(id) != null) {
      // Nothing to do.
      // The caller should set the UI to active (not stale)
      return id;
    }

    // Well - the server has cleared the game and a new game has started
    // The client will be admited as new
    return addNewClient(name);
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
