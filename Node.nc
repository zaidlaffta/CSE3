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

///
int Neighbor_protocol = 0;
int FLOODING_Protocol = 0;
event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      if(len==sizeof(pack)){
      	 pack* myMsg = (pack*) payload;
      	 // Don't print messages from neighbor probe packets or DV packets or 
      	 if( strcmp( (char*)(myMsg->payload), "NeighborProbing") && (myMsg->protocol) != PROTOCOL_PING && myMsg->protocol != PROTOCOL_PINGREPLY) {
      		dbg(GENERAL_CHANNEL, "Packet Received\n");
      	 	dbg(GENERAL_CHANNEL, "%d\n", myMsg -> protocol);
            dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
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
      //dbg(GENERAL_CHANNEL, "The packet received is currpted!!!! \n")
      //Print out the total number of times Neighbor discovery called 
      //dbg(GENERAL_CHANNEL, "Total Neighbor Discovery %d \n", Neighbor_protocol);
      //print out the total number of times Flooding was called
      //dbg(GENERAL_CHANNEL, "Total Flooding %d \n", FLOODING_Protocol);
      //return msg;
      dbg(GENERAL_CHANNEL, "Packet Received\n");
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }
/////////////////////////////////////////////
 
 

   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
   dbg(GENERAL_CHANNEL, "PING EVENT\n");
   makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
   call Sender.send(sendPackage, destination);

   dbg(GENERAL_CHANNEL, "Calling Flooding ping\n");
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
