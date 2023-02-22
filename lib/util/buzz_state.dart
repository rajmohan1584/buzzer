enum BuzzState {
  // Client
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
