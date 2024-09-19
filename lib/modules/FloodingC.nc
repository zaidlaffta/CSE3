// Configuration
#define AM_FLOODING 79

configuration FloodingC{
  provides interface SimpleSend as LSPSender;
  provides interface SimpleSend as FloodSender;
  provides interface SimpleSend as RouteSender;
  uses interface List<lspLink> as lspLinkC;
  uses interface Hashmap<int> as HashmapC;
  /*provides interface Receive as MainReceive;
  provides interface Receive as ReplyReceive;*/
}

implementation{
  components FloodingP;
  components new SimpleSendC(AM_FLOODING);
  components new AMReceiverC(AM_FLOODING);

  // Wire Internal Components All togather 
  FloodingP.InternalSender -> SimpleSendC;
  FloodingP.InternalReceiver -> AMReceiverC;
  FloodingP.lspLinkList = lspLinkC;
  FloodingP.routingTable = HashmapC;

  // Provide External Interfaces.
  components NeighborDiscoveryC;
  FloodingP.NeighborDiscovery -> NeighborDiscoveryC;

  FloodSender = FloodingP.FloodSender;
  LSPSender = FloodingP.LSPSender;
  RouteSender = FloodingP.RouteSender;

  components new ListC(pack, 64) as packetListC;
  FloodingP.packetList -> packetListC;

}