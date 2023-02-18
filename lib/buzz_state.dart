enum BuzzState {
  clientWaitingToJoin,
  clientWwaitingForCmd,
  clientAreYouReady,
  clientReady,

  // Server
  serverWaitingToCreate,
  serverListining
}
