#include <Timer.h>
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/protocol.h"
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"


module LinkStateRoutingP{

	uses interface Timer<TMilli> as PeriodicTimer;
	uses interface SimpleSend as Sender;
	uses interface Receive as Receive;
	uses interface NeighborDiscovery;
	
	provides interface LinkStateRouting;	
}

implementation {
	//just use an array to do it
	LinkStateRoutingS LinkStateRoutingS[255];
	//keeps track of number of items in the array
	uint16_t counter; 

	pack myMsg;
	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length);
	
	command void LinkStateRouting.start(){		
		dbg(ROUTING_CHANNEL, "Starting Routing\n");
		call NeighborDiscovery.start();
		call PeriodicTimer.startPeriodic(10000);
	}
	
	command uint16_t LinkStateRouting.getNextHop(uint16_t finalDest){		
		uint32_t i = 0;	
		for (i = 0; i < 255; i++) {
			if (LinkStateRoutingS[i].dest == finalDest && LinkStateRoutingS[i].cost < 999) {
				return LinkStateRoutingS[i].nextHop;
			}
		}
		
		return 999;
	}
	
	uint32_t findEntry(uint16_t dest) {
		uint32_t i;
		for (i = 0; i < counter; i++) {
			if (LinkStateRoutingS[i].dest == dest) {
				return i;
			}
		}
		return 999;
	}
	
	void addToLinkStateRouting(uint16_t dest, uint16_t cost, uint16_t nextHop){
		
		if (counter >= 255 || dest == TOS_NODE_ID) {
	
		} else {
			LinkStateRoutingS[counter].dest = dest;
			LinkStateRoutingS[counter].cost = cost;	
			LinkStateRoutingS[counter].nextHop = nextHop;	
			counter++;
		}
		return;
	}
	
	
	void getNeighbors(){
		uint16_t i = 0;
		uint16_t j = 0;
		void* tempNeighb;
		uint32_t tempTableSize = 0;
		
		
		struct neighborTableS TempNeighbors[255];
		tempNeighb = call NeighborDiscovery.getNeighborList();
		tempTableSize = call NeighborDiscovery.getNeighborListSize();
		memcpy(TempNeighbors, tempNeighb, sizeof(neighborTableS)*255);
		
		//add neighbor to the list with a cost of 1
		for (j = 0; j < tempTableSize; j++){
			if (findEntry(TempNeighbors[j].node)) {
				addToLinkStateRouting(TempNeighbors[j].node, 1, TempNeighbors[j].node);
			}
		}
		
		//set all neighbors to 999 to clear them 
		for (i = 0; i < counter; i++){
			if (LinkStateRoutingS[i].cost == 1){
				LinkStateRoutingS[i].cost = 999;
			}
		}	
		
		//goes through the routing table and only grabs neighbors who are in the refreshed neighbor list, old neighbors dies
		for (i = 0; i < counter; i++){
			for (j = 0; j < tempTableSize; j++){
				if (TempNeighbors[j].node == LinkStateRoutingS[i].dest){
					LinkStateRoutingS[i].nextHop = LinkStateRoutingS[i].dest;
					LinkStateRoutingS[i].cost = 1;		
				}
			}
				
		}
		
	}
	
	void sendLinkStateRouting(){
		uint16_t i = 0;
		uint16_t j = 0;
		LinkStateRoutingS tempLinkStateRouting[1];
		
		
		//remove values
		for (i = 0; i < counter; i++){			
			if (LinkStateRoutingS[i].cost == 999){
				LinkStateRoutingS[i].nextHop = 999;
				LinkStateRoutingS[i].cost = 999;
			}
		}
		//finds and sends neighbors only, Neighbors nexthop and dest are the same
		for (i = 0; i < counter; i++){
			if(LinkStateRoutingS[i].dest == LinkStateRoutingS[i].nextHop && LinkStateRoutingS[i].nextHop != 999){
				tempLinkStateRouting[j].dest = LinkStateRoutingS[i].dest;
				tempLinkStateRouting[j].nextHop = LinkStateRoutingS[i].nextHop;
				tempLinkStateRouting[j].cost = LinkStateRoutingS[i].cost;
				
		
				makePack(&myMsg, TOS_NODE_ID, AM_BROADCAST_ADDR, 0, 0, PROTOCOL_PING, (uint8_t*)tempLinkStateRouting, sizeof(LinkStateRoutingS)*1);
				call Sender.send(myMsg, myMsg.dest);
			}	
		}
	}
	
	event void PeriodicTimer.fired(){
		
		getNeighbors();
		sendLinkStateRouting();
		
	}
	
	event message_t* Receive.receive(message_t* raw_msg, void* payload, uint8_t len){
		LinkStateRoutingS tempLinkStateRouting[1];
		uint16_t i = 0;
		uint32_t j = 0;
		
		pack *msg = (pack *) payload;	
		memcpy(tempLinkStateRouting, msg->payload, sizeof(LinkStateRoutingS)*1);
		j = findEntry(tempLinkStateRouting[i].dest);	
		//if I am neighbor, remove just in case, only draw neighbors from my own pool
		if (tempLinkStateRouting[i].nextHop == TOS_NODE_ID){
			tempLinkStateRouting[i].cost = 999;
		
		}
		//if it is in the list
		if (j != 999) {
			if (LinkStateRoutingS[j].nextHop == msg->src) {
				//update the cost 
				if (tempLinkStateRouting[i].cost < 999){
					LinkStateRoutingS[j].cost = tempLinkStateRouting[i].cost + 1;
				}
			//if my cost is lower update
			} else if ((tempLinkStateRouting[i].cost + 1) < LinkStateRoutingS[j].cost) {
					LinkStateRoutingS[j].cost = tempLinkStateRouting[i].cost + 1;
					LinkStateRoutingS[j].nextHop = msg->src;
			}
				
		} else {
			addToLinkStateRouting(tempLinkStateRouting[i].dest, tempLinkStateRouting[i].cost, msg->src);
		}
		
		return raw_msg;
	}
	
	command void LinkStateRouting.print(){
		uint32_t i = 0;
		
		dbg(ROUTING_CHANNEL, "Printing Routing Table\n");
		dbg(ROUTING_CHANNEL, "Dest\tHop\tCount\n");
				
		for (i = 0; i < 255; i++) {
			if (LinkStateRoutingS[i].dest != 0) {
				dbg( ROUTING_CHANNEL, "%u\t\t%u\t%u\n", LinkStateRoutingS[i].dest, LinkStateRoutingS[i].nextHop, LinkStateRoutingS[i].cost);
			}
		}
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