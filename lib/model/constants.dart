import 'package:flutter/material.dart';

// These are actually GLOBALs - TODO - rename to GLOBAL ?
class CONST {
  static String appVersion = "?.?.?";
  static String myIP = "?.?.?.?";
  static String myWifi = "?";
  static String iPhoneIP = "192.168.50.250";
  static String macBookIP = "192.168.50.181";
  static String multicastIP = "239.1.2.3";
  static int multicastPort = 54321;

  static bool androidSimulator = false;

  // Server sends message out.
  // Each client listens on this address.
  static String serverMulticastIP = "224.0.0.1";
  static int serverMulticastPort = 2345;

  // Server sends message out.
  // Each client listens on this address.
  static String clientMulticastIP = "224.0.0.2";
  static int clientMulticastPort = 3456;

  static int clientMinScore = 0;
  static int clientMaxScore = 9999999;
  static int clientDeltaScore = 1;

  static Color textColor = const Color(0xff82fb4c);
}
