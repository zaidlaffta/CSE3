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
   // make packet given in the lab
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   event void Boot.booted(){
      call AMControl.start();
      dbg(GENERAL_CHANNEL, "Booted\n");
      //call starting neighbordiscovery function
      call NeighborDiscovery.start();
      call PrintTimer.startPeriodic(500);
      dbg(FLOODING_CHANNEL, "time started");
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){
      if(err != SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio is not working \n");
      }else{
         //retray again!
         call AMControl.start();
      }
   }

// Int to count number of times neighbor discovery executed 
int Neighbor_protocol = 0;
// int to count number of times Flooding executed 
int FLOODING_Protocol = 0;

event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      if(len==sizeof(pack)){
      	 pack* myMsg = (pack*) payload;
      	 // Don't print messages from neighbor probe packets or DV packets or 
      	 if( strcmp( (char*)(myMsg->payload), "NeighborProbing") && (myMsg->protocol) != PROTOCOL_PING && myMsg->protocol != PROTOCOL_PINGREPLY) {
      		//debug is the packet receviced in the right protocol form 
            dbg(GENERAL_CHANNEL, "Packet Received\n");
      	 	
            dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
            dbg(GENERAL_CHANNEL, "%d\n", myMsg -> protocol);
      	 }
         
         else if (myMsg->dest == 0) {
            dbg(GENERAL_CHANNEL, "Neighbor Discovery called here \n");
      		call NeighborDiscovery.discover(myMsg);
            Neighbor_protocol++;
            dbg(GENERAL_CHANNEL, "number of times Neighbor Discovery Called %d \n", Neighbor_protocol);
      	 }
          
          else {
            dbg(GENERAL_CHANNEL, "Flooding function called here\n");
            call Flooding.Flood(myMsg);
            FLOODING_Protocol++;
            dbg(GENERAL_CHANNEL, "number of time Flooding Protocal Executed %d \n", FLOODING_Protocol);
          }
         return msg;
      }
      // debug statement if the packet received is not correct or currpted. 
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      dbg(GENERAL_CHANNEL, "Packet Received\n");
      dbg(GENERAL_CHANNEL, "This is currpted packet \n");
      return msg;
   }
/////////////////////////////////////////////
 
 

   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
   dbg(GENERAL_CHANNEL, "PING EVENT\n");
   makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
   call Sender.send(sendPackage, destination);
   //Calling Flood protocol here
   dbg(GENERAL_CHANNEL, "Calling Flooding ping\n");
   call Flooding.ping(destination, payload);
}

  // 
   event void CommandHandler.printNeighbors(){  
      call NeighborDiscovery.printNeighbors();
      dbg(GENERAL_CHANNEL, "Command");
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
