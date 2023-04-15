class BuzzDef {
  static get client => "C"; // Client
  static get server => "S"; // Server
  static get board => "B"; // Score Board

  static get newClientRequest => "NCQ";
  static get rejoinClientRequest => "RCQ";

  static get newClientResponse => "NCR";
  static get rejoinClientResponse => "RCR";

  static get lgq => "LGQ"; // Login Request
  static get lgr => "LGR"; // Login Response
  static get hbq => "HBQ"; // Heartbeat Request
  static get hbr => "HBR"; // Heartbeat Response

  static get ping => "PING";
  static get pong => "PONG";

  static get areYouReady => "AUR";
  static get iAmReady => "IAR";

  static get startRound => "START-ROUND";
  static get endRound => "END-ROUND";

  //static get buzz => "BUZZ";
  static get buzzNo => "BUZZ-NO";
  static get buzzYes => "BUZZ-YES";

  static get countdown => "COUNTDOWN";
  static get score => "SCORE";
  static get topBuzzers => "TOP-BUZZERS";

  static get id => "ID";
  static get name => "NAME";
  static get avatar => "AVATAR";

  static get app => "APP";
  static get version => "VERSION";
  static get clients => "CLIENTS";
  static get count => "COUNT";
  static get sec => "SEC";
}

typedef BuzzMap = Map<String, dynamic>;
