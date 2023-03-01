enum BuzzState {
  // Client
  clientWaitingForServer,
  clientWaitingToJoin,
  clientWaitingToLogin,
  clientWaitingForLoginResponse,
  clientLoggedIn,
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
