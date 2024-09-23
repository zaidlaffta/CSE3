/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"
#include <string.h>


module Node{
   //connecting flooding module 
   uses interface Flooding as Flooding;
   //connecting neighbor discovery module
   uses interface NeighborDiscovery as NeighborDiscovery;

   //existing code givne by the instractor
   uses interface Boot;
   uses interface SplitControl as AMControl;
   uses interface Receive;
  

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;
}

implementation{
   pack sendPackage;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();
      dbg(GENERAL_CHANNEL, "Booted\n");
      //call starting neighbordiscovery function
      call NeighborDiscovery.start();
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
      }
      else if (myMsg->dest == 0) {
         call NeighborDiscovery.discover(myMsg);
         dbg(GENERAL_CHANNEL, "Neighbor Discovery being called in here\n");

      }
      /*else if {
         call Flooding.Flood(myMsg);
         dbg(GENERAL_CHANNEL, "This Flooding protocol working");
      }*/
      
         else if (myMsg->protocol == PROTOCOL_FLOOD) {
         call Flooding.Flood(myMsg);
         dbg(GENERAL_CHANNEL, "Flooding protecover being called in here")
      }

         return msg;

      dbg (GENERAL_CHANNEL, "we received a packet"); 
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }
   

   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, destination);
      dbg(GENERAL_CHANNEL, "Calling Flooding ping ");
      call Flooding.ping(destination, payload);
   }

  
     

   event void CommandHandler.printNeighbors(){
      call NeighborDiscovery.printNeighbors();
   }

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
