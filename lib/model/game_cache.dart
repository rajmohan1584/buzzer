import 'dart:convert';
import 'package:nanoid/non_secure.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';

import '../util/log.dart';

const _app = "app";
const _version = "version";
const _clients = "clients";
const _count = "count";

const _name = "name";
const _score = "score";
int _c = 0;

class GameCache {
  static late final SharedPreferences _prefs;

  //////////////////////////////////////////////////////////////////////
  //
  static Future init() async {
    // Initialize once
    _prefs = await SharedPreferences.getInstance();
  }

  static clear() async {
    final clients = getClients();

    for (var cid in clients) {
      await _prefs.remove(cid);
    }
    await _prefs.remove(_clients);
    await _prefs.remove(_count);
  }

  //////////////////////////////////////////////////////////////////////
  // hasCache
  //
  static Future<bool> hasCache() async {
    String? sClients = _prefs.getString(_clients);
    if (sClients == null) {
      return false;
    }
    return true;
  }

  //////////////////////////////////////////////////////////////////////
  // hasCache
  //
  static Future<int> getNextClientCount() async {
    int? count = _prefs.getInt(_count);
    if (count == null) {
      // first participent
      count = 1;
    } else {
      count++;
    }

    _prefs.setInt(_count, count);

    return count;
  }

  //////////////////////////////////////////////////////////////////////
  // hasCache
  //
  static void dump() async {
    final List<String> clients = getClients();
    // No Game Cache.
    Log.log("GameDump> Game Cache has `${clients.length} clients.");

    for (var cid in clients) {
      final Map<String, dynamic>? client = getClient(cid);

      if (client == null) {
        // Bug. Did not cleanup?
        Log.log('$cid - Bug. Did not cleanup?');
        // TODO - assert(false);
      } else {
        Log.log('$cid - ${client.toString()}');
      }
    }
  }

  //////////////////////////////////////////////////////////////////////
  // Get Set clients
  //
  static List<String> getClients() {
    String? sClients = _prefs.getString(_clients);
    if (sClients != null) {
      // clients is a csv
      return sClients.split(",");
    }
    return [];
  }

  static setClients(List<String> clients) async {
    String sClients = clients.join(",");
    await _prefs.setString(_clients, sClients);
  }

  //////////////////////////////////////////////////////////////////////
  // Add Remove client
  //
  static Future<String> addNewClient(String id) async {
    //
    // There is nothing to check.
    // A new name gets generated for each new client.
    // Also if a disconnected client comes in as a new one,
    //    the score will be set to zero and the old connection will be stale.
    //    And the stale connection should be purged later - // TODO
    //

    // Create a new name
    int count = ++_c; //await getNextClientCount();
    String newName = 'Participant_$count';

    // Add the id to the array of client ids.
    List<String> clients = getClients();
    clients.add(id);
    setClients(clients);

    // Also create a new key with id and the {}
    //assert(await getClient(id) == null);
    Map<String, dynamic> client = {};
    client[_name] = newName;
    client[_score] = 0;
    setClient(id, client);

    return newName;
  }

/*
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
*/

  static removeClient(id) async {
    List<String> clients = getClients();
    if (!clients.contains(id)) {
      // client does exists - Probably New
      return;
    }
    // TODO - remove key=id

    clients.remove(id);
    setClients(clients);
  }

  //////////////////////////////////////////////////////////////////////
  // Set Get Client
  //
  static Map<String, dynamic>? getClient(String id) {
    String? sClient = _prefs.getString(id);
    if (sClient == null) {
      return null;
    }

    Map<String, dynamic> client = json.decode(sClient);
    return client;
  }

  static Future<bool> setClient(String id, Map<String, dynamic> client) async {
    String sClient = json.encode(client);
    await _prefs.setString(id, sClient);
    return true;
  }

  //////////////////////////////////////////////////////////////////////
  // Set Get Client
  //
  static Future<bool> setScore(String id, int score) async {
    Map<String, dynamic>? client = getClient(id);
    if (client == null) {
      return false;
    }

    client[_score] = score;
    await setClient(id, client);
    return true;
  }
}
