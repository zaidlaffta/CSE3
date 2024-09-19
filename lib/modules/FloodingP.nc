//CSE160
//Project 1

#include "../../includes/channels.h"
#include "../../includes/lsp.h"
#include "../../includes/CommandMsg.h"
//This is the module
module FloodingP{
  provides interface SimpleSend as FloodSender;
  provides interface SimpleSend as LSPSender;
  provides interface SimpleSend as RouteSender;
// Use interfaces as part of module
  uses interface SimpleSend as InternalSender;
  uses interface Receive as InternalReceiver;
  uses interface List<pack> as packetList;
  uses interface List<lspLink> as lspLinkList;
  uses interface NeighborDiscovery;
  uses interface Hashmap<int> as routingTable;
}

implementation{
  uint16_t seqNumber = 0;
  pack sendPackage;
  uint32_t tempDest;
  bool findMyPacket(pack *Package);
  void checkPackets(pack *myMsg);
  void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
//error command
  command error_t FloodSender.send(pack msg, uint16_t dest){
    msg.src = TOS_NODE_ID;
    msg.protocol = PROTOCOL_PING;
    msg.seq = seqNumber++;
    msg.TTL = MAX_TTL;
    call InternalSender.send(msg, AM_BROADCAST_ADDR);
  }
// Make packet code from the lab in Friday. 
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
         Package->src = src;
         Package->dest = dest;
         Package->TTL = TTL;
         Package->seq = seq;
         Package->protocol = protocol;
         memcpy(Package->payload, payload, length);
      }
    // Need to implement timer as shown in the lab lecture 
  command error_t LSPSender.send(pack msg, uint16_t dest)
  {
    call InternalSender.send(msg, AM_BROADCAST_ADDR);
  }

  command error_t RouteSender.send(pack msg, uint16_t dest)
  {
    msg.seq = seqNumber++;
    call InternalSender.send(msg, dest);
  }

// need to finish receiver 
  event message_t* InternalReceiver.receive(message_t* msg, void* payload, uint8_t len)
  {
    if(len==sizeof(pack)){
      pack* myMsg=(pack*) payload;
      if(myMsg->TTL == 0 || findMyPacket(myMsg))
      {
        return  msg;
        }else if(TOS_NODE_ID == myMsg->dest)
        { //Destination found use debug to show result
          dbg(FLOODING_CHANNEL, "This is the Destination from : %d to %d\n",myMsg->src,myMsg->dest);
          dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
          if(myMsg->protocol == PROTOCOL_PING)
          {
            dbg(FLOODING_CHANNEL, "Going to ping");
            return msg;
          }     
            if(myMsg->protocol == PROTOCOL_PINGREPLY)
              call NeighborDiscovery.neighborReceived(myMsg);
            return msg;
            checkPackets(myMsg);
            /* //code is not working and breaking the program, need to debug. 
            if(call routingTable.contains(myMsg -> src)){
              dbg(NEIGHBOR_CHANNEL, "to get to:%d, send through:%d\n", myMsg -> dest, call routingTable.get(myMsg -> dest));
              makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL-1, myMsg->protocol, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
              call InternalSender.send(sendPackage, call routingTable.get(myMsg -> dest));
            }*/
            return msg;
        }
    }
// Need to implement pack beaconup as giving in the lab lecture
//
// need to find mypacket impelentation 
//   

     
  }
}
