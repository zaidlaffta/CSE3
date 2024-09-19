// Module
#include "../../includes/channels.h"
#include "../../includes/packet.h"

#define BEACON_PERIOD 1000

module NeighborDiscoveryP{

  // provides intefaces
  provides interface NeighborDiscovery;

  /// uses interface
  uses interface Timer<TMilli> as neigbordiscoveryTimer;
  uses interface SimpleSend as FloodSender;
  uses interface List<pack> as neighborList;
  uses interface Random as Random;

}

implementation{
  pack sendPackage;
  uint16_t seqNumber = 0;
  uint16_t neighborAge = 0;
  bool findMyNeighbor(pack *Package);
  void removeNeighbors();

  void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

  command void NeighborDiscovery.start(){
    // one shot timer and include random element to it.
    uint32_t startTimer;
    dbg(GENERAL_CHANNEL, "Booted\n");
    startTimer = (20000 + (uint16_t) ((call Random.rand16())%5000));;
    //call neigbordiscoveryTimer.startPeriodic(startTimer);
    call neigbordiscoveryTimer.startOneShot(10000);
  }

  command void NeighborDiscovery.neighborReceived(pack *myMsg){
    if(!findMyNeighbor(myMsg))
    {
      call neighborList.pushback(*myMsg);
    }

  }

  command void NeighborDiscovery.print(){
    if(call neighborList.size() > 0)
       {
         uint16_t neighborListSize = call neighborList.size();
         uint16_t i = 0;
         //dbg(NEIGHBOR_CHANNEL, "***the NEIGHBOUR size of node %d is :%d\n",TOS_NODE_ID, neighborListSize);
         for(i = 0; i < neighborListSize; i++)
         {
           pack neighborNode = call neighborList.get(i);
           dbg(NEIGHBOR_CHANNEL, "***the NEIGHBOURS  of node  %d is :%d\n",TOS_NODE_ID,neighborNode.src);
         }
       }
       else{
         dbg(COMMAND_CHANNEL, "***0 NEIGHBOURS  of node  %d!\n",TOS_NODE_ID);
       }
  }

  event void neigbordiscoveryTimer.fired()
      {
        char* neighborPayload = "Neighbor Discovery";
        uint16_t size = call neighborList.size();
        uint16_t i = 0;
        if(neighborAge==MAX_NEIGHBOR_AGE){
          //dbg(NEIGHBOR_CHANNEL,"removing neighbor of %d with Age %d \n",TOS_NODE_ID,neighborAge);
          neighborAge = 0;
          for(i = 0; i < size; i++) {
            call neighborList.popfront();
          }
        }
        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 2, PROTOCOL_PING, seqNumber,  (uint8_t*) neighborPayload, PACKET_MAX_PAYLOAD_SIZE);
        neighborAge++;
        //Check TOS_NODE_ID and destination
        call FloodSender.send(sendPackage, AM_BROADCAST_ADDR);
      }



/*
  Command Receive(){
    // If the destination is AM_BROADCAST, then respond directly
    send(msg, msg.src);
    // else
    add neighborlist
    //
  }*/

  // each neighbor time since last response. ( let’s set it to 5)
  void removeNeighbors()
      {
        uint16_t size = call neighborList.size();
        uint16_t i = 0;
        for(i = 0; i < size; i++) {
          call neighborList.popback();
        }
      }

      bool findMyNeighbor(pack *Package)
      {

        uint16_t size = call neighborList.size();
        uint16_t i = 0;
        pack checkIfExists;
        for(i = 0; i < size; i++) {
          checkIfExists = call neighborList.get(i);
          if(checkIfExists.src == Package->src && checkIfExists.dest == Package->dest) {
            return TRUE;
          }
        }
        return FALSE;
      }

      void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
         Package->src = src;
         Package->dest = dest;
         Package->TTL = TTL;
         Package->seq = seq;
         Package->protocol = protocol;
         memcpy(Package->payload, payload, length);
      }
}