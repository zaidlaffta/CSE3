// Module
#include "../../includes/channels.h"
#include "../../includes/lsp.h"
#include "../../includes/CommandMsg.h"

module FloodingP{
  provides interface SimpleSend as FloodSender;
  provides interface SimpleSend as LSPSender;
  provides interface SimpleSend as RouteSender;

  // Internal
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


  lspLink lspL;
  uint16_t lspAge = 0;

  command error_t FloodSender.send(pack msg, uint16_t dest){
    msg.src = TOS_NODE_ID;
    msg.protocol = PROTOCOL_PING;
    msg.seq = seqNumber++;
    msg.TTL = MAX_TTL;
    //dbg(FLOODING_CHANNEL, "Flooding Network: %s\n", msg.payload);
    call InternalSender.send(msg, AM_BROADCAST_ADDR);
  }

  command error_t LSPSender.send(pack msg, uint16_t dest){
//    dbg(ROUTING_CHANNEL, "LSP Network: %s\n", msg.payload);
    call InternalSender.send(msg, AM_BROADCAST_ADDR);
  }

  command error_t RouteSender.send(pack msg, uint16_t dest){
    msg.seq = seqNumber++;
    call InternalSender.send(msg, dest);
  }


  event message_t* InternalReceiver.receive(message_t* msg, void* payload, uint8_t len){
    //dbg(FLOODING_CHANNEL, "Receive: %s", msg.payload);
    // Check to see if we have seen it before?
    if(len==sizeof(pack)){
      pack* myMsg=(pack*) payload;
      if(myMsg->TTL == 0 || findMyPacket(myMsg))
      {
        //Drop the packet if we've seen it or if it's TTL has run out: i.e. do nothing
        //dbg(FLOODING_CHANNEL, "Packet Exists in the List so dropping packet with seq %d from %d\n", myMsg->seq, TOS_NODE_ID);
        return  msg;
        }else if(TOS_NODE_ID == myMsg->dest)
        { //Destination found
          dbg(FLOODING_CHANNEL, "This is the Destination from : %d to %d\n",myMsg->src,myMsg->dest);
          dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
          //Ping Back to the Source
          if(myMsg->protocol == PROTOCOL_PING)
          {
            dbg(GENERAL_CHANNEL, "PING-REPLY EVENT \n");
            dbg(FLOODING_CHANNEL, "Going to ping from: %d to %d with seq %d\n", myMsg->dest,myMsg->src,myMsg->seq);

            checkPackets(myMsg);
            if(call routingTable.contains(myMsg -> src)){
              dbg(NEIGHBOR_CHANNEL, "to get to:%d, send through:%d\n", myMsg -> src, call routingTable.get(myMsg -> src));
              makePack(&sendPackage, myMsg->dest, myMsg->src, MAX_TTL, PROTOCOL_PINGREPLY, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
              call InternalSender.send(sendPackage, call routingTable.get(myMsg -> src));
            }
            else{
              dbg(NEIGHBOR_CHANNEL, "Couldn't find the routing table for:%d so flooding\n",TOS_NODE_ID);
              makePack(&sendPackage, myMsg->dest, myMsg->src, myMsg->TTL-1, PROTOCOL_PINGREPLY, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
              call InternalSender.send(sendPackage, AM_BROADCAST_ADDR);
            }
            return msg;

            }
            else if(myMsg->protocol == PROTOCOL_PINGREPLY)
            {
              dbg(FLOODING_CHANNEL, "Received a Ping Reply from %d\n", myMsg->src);
            }

            return msg;
          }else if(myMsg->dest == AM_BROADCAST_ADDR)
          {
            if(myMsg->protocol == PROTOCOL_LINKSTATE)
            {
              uint16_t i,j = 0;
              uint16_t k = 0;
              bool enterdata = TRUE;
              for(i = 0; i < myMsg->seq; i++)
              {
                for(j = 0; j < call lspLinkList.size(); j++)
                {
                  lspLink lspacket = call lspLinkList.get(j);
                  if(lspacket.src == myMsg->src && lspacket.neighbor==myMsg->payload[i])
                  {
                    enterdata = FALSE;
                  }
                }
              }

              if(enterdata)
              {
                for(k = 0; k < myMsg->seq; k++)
                {
                  lspL.neighbor = myMsg->payload[k];
                  lspL.cost = 1;
                  lspL.src = myMsg->src;
                  call lspLinkList.pushback(lspL);
                  //dbg(ROUTING_CHANNEL,"$$$Neighbor: %d\n",lspL.neighbor);
                }
                makePack(&sendPackage, myMsg->src, AM_BROADCAST_ADDR, myMsg->TTL-1 , PROTOCOL_LINKSTATE, myMsg->seq, myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
                //Check TOS_NODE_ID and destination
                call InternalSender.send(sendPackage,AM_BROADCAST_ADDR);
              }
              else{
                //dbg(ROUTING_CHANNEL,"LSP already exists for %d\n",TOS_NODE_ID);
              }
            }
           //Handle neighbor discovery packets here
            if(myMsg->protocol == PROTOCOL_PING)
            {
              //dbg(GENERAL_CHANNEL,"Starting Neighbor Discover for %d\n",myMsg->src);
              makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, myMsg->TTL-1 , PROTOCOL_PINGREPLY, seqNumber, myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
              //Check TOS_NODE_ID and destination
              call InternalSender.send(sendPackage, myMsg->src);

            }

            if(myMsg->protocol == PROTOCOL_PINGREPLY)
            {
              //dbg(GENERAL_CHANNEL,"AT Neighbor PingReply\n");
              call NeighborDiscovery.neighborReceived(myMsg);
            }
            //call lsrTimer.startPeriodic(60000 + (uint16_t)((call Random.rand16())%200));
            return msg;
          }
          else
          {
            checkPackets(myMsg);
            if(call routingTable.contains(myMsg -> src)){
              dbg(NEIGHBOR_CHANNEL, "to get to:%d, send through:%d\n", myMsg -> dest, call routingTable.get(myMsg -> dest));
              makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL-1, myMsg->protocol, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
              call InternalSender.send(sendPackage, call routingTable.get(myMsg -> dest));
            }
            else{
              dbg(NEIGHBOR_CHANNEL, "Couldn't find the routing table for:%d so flooding\n",TOS_NODE_ID);
              makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL-1, myMsg->protocol, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
              call InternalSender.send(sendPackage, AM_BROADCAST_ADDR);
            }
            return msg;
          }

        }
        dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
        return msg;
      }

      
      
      bool findMyPacket(pack *Package)
      {
        uint16_t size = call packetList.size();
        uint16_t i = 0;
        pack checkIfExists;
        for(i = 0; i < size; i++) {
          checkIfExists = call packetList.get(i);
          if(checkIfExists.src == Package->src && checkIfExists.dest == Package->dest && checkIfExists.seq == Package->seq) {
            return TRUE;
          }
        }
        return FALSE;
      }

      void checkPackets(pack *myMsg){
              if(call packetList.isFull())
              { //check for List size. If it has reached the limit. #popfront
                call packetList.popfront();
              }
              //Pushing Packet to PacketList
              call packetList.pushback(*myMsg);
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