enum BuzzState {
  // Client
  clientWaitingToJoin,
  clientWaitingForCmd,
  clientAreYouReady,
  clientReady,

  // Score Board - client
  scoreBoardWaitingToJoin,
  scoreBoardConnected,

  // Server
  serverWaitingToCreate,
  serverWaitingForClients,
  serverListining,
}
