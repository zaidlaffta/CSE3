// Configuration
#define AM_NEIGHBOR 62

configuration NeighborDiscoveryC{
  provides interface NeighborDiscovery;
  uses interface List<pack> as neighborListC;
}

implementation{
  components NeighborDiscoveryP;
  //components new TimerMilliC() as neigbordiscoveryTimer;
  components new SimpleSendC(AM_NEIGHBOR);
  components new AMReceiverC(AM_NEIGHBOR);

  NeighborDiscoveryP.neighborList = neighborListC;

  components RandomC as Random;
  NeighborDiscoveryP.Random -> Random;

  // External Wiring
  NeighborDiscovery = NeighborDiscoveryP.NeighborDiscovery;

  components new TimerMilliC() as myTimerC; //create a new timer with alias “myTimerC”
  NeighborDiscoveryP.neigbordiscoveryTimer -> myTimerC; //Wire the interface to the component

  components FloodingC;
  NeighborDiscoveryP.FloodSender -> FloodingC.FloodSender;

  // internal Wiring
  //NeighborDiscoveryP.SimpleSend -> SimpleSendC;
  //NeighborDiscoveryP.Receve -> AMReceive;
  //NeighborDiscoveryP.beaconTimer -> beaconTimer;
}