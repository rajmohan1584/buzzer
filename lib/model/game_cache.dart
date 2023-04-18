import 'dart:convert';
import 'package:buzzer/model/defs.dart';
import 'package:buzzer/util/language.dart';
import 'package:buzzer/util/util.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/log.dart';

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
    await _prefs.remove(BuzzDef.clients);
    await _prefs.remove(BuzzDef.count);
  }

  //////////////////////////////////////////////////////////////////////
  // hasCache
  //
  static bool hasCache() {
    String? sClients = _prefs.getString(BuzzDef.clients);
    if (sClients == null) {
      return false;
    }
    return true;
  }

  //////////////////////////////////////////////////////////////////////
  //
  static int getNextClientCount() {
    return ++_c;
  }

  static String getNextClientName() {
    int count = getNextClientCount();
    return 'நண்பர்_$count';
  }

  //////////////////////////////////////////////////////////////////////
  // hasCache
  //
  static void dump() {
    final List<String> clients = getClients();
    // No Game Cache.
    Log.log("GameDump> Game Cache has ${clients.length} clients.");

    for (var cid in clients) {
      final BuzzMap? client = getClient(cid);

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
    String? sClients = _prefs.getString(BuzzDef.clients);
    if (sClients != null) {
      // clients is a csv
      return sClients.split(",");
    }
    return [];
  }

  static setClients(List<String> clients) async {
    String sClients = clients.join(",");
    await _prefs.setString(BuzzDef.clients, sClients);
  }

  //////////////////////////////////////////////////////////////////////
  // Add Remove client
  //
  static Future<BuzzMap> addNewClient(BuzzMap data) async {
    //
    // There is nothing to check.
    // If client did not identify him/herself, a new name gets generated.
    // Also if a disconnected client comes in as a new one,
    //    the score will be set to zero and the old connection will be stale.
    //    And the stale connection should be purged later - // TODO
    //

    // Create a new name
    String nextName = getNextClientName();

    String id = data[BuzzDef.id];
    assert(id.isNotEmpty);
    int avatar = data[BuzzDef.avatar] ?? 0;

    // Try to use the client passed in data (from cache)
    String name = data[BuzzDef.name] ?? "";
    StringUtf8 nameUtf8 = LANG.parseNameUtf8(data);
    if (nameUtf8.isNotEmpty) name = LANG.socket2Name(nameUtf8);

    String newName = name.isEmpty ? nextName : name;

    // If the user did not pick an avatar - we'll decide what to do later
    /*
    int newAvatar = avatar <= 1
        ? UTIL.randomInt(min: 1, max: 6)
        : avatar; // TODO - get the max from ??
    */
    int newAvatar = avatar;

    // Add the id to the array of client ids.
    List<String> clients = getClients();
    clients.add(id);
    setClients(clients);

    // Also create a new key with id and the {}
    //assert(await getClient(id) == null);
    data[BuzzDef.name] = newName;
    data[BuzzDef.nameUtf8] = LANG.name2Socket(newName);
    data[BuzzDef.avatar] = newAvatar;
    data[BuzzDef.score] = 0;
    await setClient(id, data);

    return data;
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
    await setClients(clients);
  }

  //////////////////////////////////////////////////////////////////////
  // Set Get Client
  //
  static BuzzMap? getClient(String id) {
    String? sClient = _prefs.getString(id);
    if (sClient == null) {
      return null;
    }

    BuzzMap client = json.decode(sClient);
    return client;
  }

  static Future<bool> setClient(String id, BuzzMap client) async {
    String sClient = json.encode(client);
    await _prefs.setString(id, sClient);
    return true;
  }

  //////////////////////////////////////////////////////////////////////
  // Set Get Client
  //
  static Future<bool> setScore(String id, int score) async {
    BuzzMap? client = getClient(id);
    if (client == null) {
      return false;
    }

    client[BuzzDef.score] = score;
    await setClient(id, client);
    return true;
  }

  //////////////////////////////////////////////////////////////////
  ///
  /// This will be called by the client.
  static BuzzMap? getSavedClientFromCache() {
    // onlu one client can be saved.
    // If running multiple instane of the program on the same box
    //   it may not work
    String sClient = _prefs.getString(BuzzDef.savedClient) ?? "";
    if (sClient.isEmpty) {
      return null;
    }
    BuzzMap savedClient = json.decode(sClient);
    return savedClient;
  }

  //////////////////////////////////////////////////////////////////
  ///
  /// This will be called by the client.
  static Future saveClientInCache(BuzzMap client) async {
    String sClient = json.encode(client);
    await _prefs.setString(BuzzDef.savedClient, sClient);
  }
}

