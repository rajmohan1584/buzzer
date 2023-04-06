class CONST {
  static String iPhoneIP = "192.168.50.250";
  static String macBookIP = "192.168.50.181";
  static String multicastIP = "239.1.2.3";
  static int multicastPort = 54321;

  // Server sends message out.
  // Each client listens on this address.
  static String serverMulticastIP = "239.1.2.3";
  static int serverMulticastPort = 4567;

  // Server sends message out.
  // Each client listens on this address.
  static String clientMulticastIP = "239.1.2.4";
  static int clientMulticastPort = 5678;

  static int clientMinScore = 0;
  static int clientMaxScore = 9999999;
  static int clientDeltaScore = 1;
}
