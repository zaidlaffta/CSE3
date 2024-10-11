#include <Timer.h>
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/protocol.h"
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"

module LinkStateRoutingP {
    provides interface LinkStateRouting;

    uses interface Timer<TMilli> as PeriodicTimer;
    uses interface SimpleSend as Sender;
    uses interface Receive as Receive;
    uses interface NeighborDiscovery;

}

implementation {
    // Just use an array to do it
    LinkStateRoutingS LinkStateRoutingS[255]; // Define the routing table
    // Keeps track of the number of items in the array
    uint16_t counter = 0; 

    pack myMsg;

    // Function to make a packet
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length);

    command void LinkStateRouting.start() {        
        dbg(ROUTING_CHANNEL, "Starting Routing\n");
        call NeighborDiscovery.start();
        call PeriodicTimer.startPeriodic(10000);
    }
    
    command uint16_t LinkStateRouting.getNextHop(uint16_t finalDest) {        
        for (uint32_t i = 0; i < counter; i++) {
            if (LinkStateRoutingS[i].dest == finalDest && LinkStateRoutingS[i].cost < 999) {
                return LinkStateRoutingS[i].nextHop;
            }
        }
        return 999;
    }
    
    uint32_t findEntry(uint16_t dest) {
        for (uint32_t i = 0; i < counter; i++) {
            if (LinkStateRoutingS[i].dest == dest) {
                return i;
            }
        }
        return 999;
    }
    
    void addToLinkStateRouting(uint16_t dest, uint16_t cost, uint16_t nextHop) {
        if (counter < 255 && dest != TOS_NODE_ID) {
            LinkStateRoutingS[counter].dest = dest;
            LinkStateRoutingS[counter].cost = cost;    
            LinkStateRoutingS[counter].nextHop = nextHop;    
            counter++;
        }
    }
    
    void getNeighbors() {
        uint16_t tempTableSize = call NeighborDiscovery.getNeighborListSize();
        struct neighborTableS TempNeighbors[255];
        void* tempNeighb = call NeighborDiscovery.getNeighborList();
        
        // Copy neighbors to local storage
        memcpy(TempNeighbors, tempNeighb, sizeof(struct neighborTableS) * tempTableSize);
        
        // Add neighbors to the list with a cost of 1
        for (uint16_t j = 0; j < tempTableSize; j++) {
            if (findEntry(TempNeighbors[j].node) == 999) {
                addToLinkStateRouting(TempNeighbors[j].node, 1, TempNeighbors[j].node);
            }
        }
        
        // Set all neighbors to 999 to clear them 
        for (uint32_t i = 0; i < counter; i++) {
            if (LinkStateRoutingS[i].cost == 1) {
                LinkStateRoutingS[i].cost = 999;
            }
        }
        
        // Refresh the routing table based on neighbors
        for (uint32_t i = 0; i < counter; i++) {
            for (uint16_t j = 0; j < tempTableSize; j++) {
                if (TempNeighbors[j].node == LinkStateRoutingS[i].dest) {
                    LinkStateRoutingS[i].nextHop = LinkStateRoutingS[i].dest;
                    LinkStateRoutingS[i].cost = 1;        
                }
            }
        }
    }
    
    void sendLinkStateRouting() {
        for (uint16_t i = 0; i < counter; i++) {
            if (LinkStateRoutingS[i].dest == LinkStateRoutingS[i].nextHop && LinkStateRoutingS[i].nextHop != 999) {
                LinkStateRoutingS tempLinkStateRouting[1];
                tempLinkStateRouting[0].dest = LinkStateRoutingS[i].dest;
                tempLinkStateRouting[0].nextHop = LinkStateRoutingS[i].nextHop;
                tempLinkStateRouting[0].cost = LinkStateRoutingS[i].cost;

                makePack(&myMsg, TOS_NODE_ID, AM_BROADCAST_ADDR, 0, 0, PROTOCOL_PING, (uint8_t*)tempLinkStateRouting, sizeof(LinkStateRoutingS[0]));
                call Sender.send(myMsg, myMsg.dest);
            }    
        }
    }
    
    event void PeriodicTimer.fired() {
        getNeighbors();
        sendLinkStateRouting();
    }
    
    event message_t* Receive.receive(message_t* raw_msg, void* payload, uint8_t len) {
        struct LinkStateRoutingS tempLinkStateRouting[1];
        pack *msg = (pack *) payload;    
        memcpy(tempLinkStateRouting, msg->payload, sizeof(struct LinkStateRoutingS));

        uint32_t j = findEntry(tempLinkStateRouting[0].dest);    
        // If I am neighbor, remove just in case
        if (tempLinkStateRouting[0].nextHop == TOS_NODE_ID) {
            tempLinkStateRouting[0].cost = 999;
        }
        // If it is in the list
        if (j != 999) {
            if (LinkStateRoutingS[j].nextHop == msg->src) {
                // Update the cost 
                if (tempLinkStateRouting[0].cost < 999) {
                    LinkStateRoutingS[j].cost = tempLinkStateRouting[0].cost + 1;
                }
            } else if ((tempLinkStateRouting[0].cost + 1) < LinkStateRoutingS[j].cost) {
                LinkStateRoutingS[j].cost = tempLinkStateRouting[0].cost + 1;
                LinkStateRoutingS[j].nextHop = msg->src;
            }
        } else {
            addToLinkStateRouting(tempLinkStateRouting[0].dest, tempLinkStateRouting[0].cost, msg->src);
        }

        return raw_msg;
    }
    
    command void LinkStateRouting.print() {
        dbg(ROUTING_CHANNEL, "Printing Routing Table\n");
        dbg(ROUTING_CHANNEL, "Dest\tHop\tCount\n");

        for (uint32_t i = 0; i < counter; i++) {
            if (LinkStateRoutingS[i].dest != 0) {
                dbg(ROUTING_CHANNEL, "%u\t\t%u\t%u\n", LinkStateRoutingS[i].dest, LinkStateRoutingS[i].nextHop, LinkStateRoutingS[i].cost);
            }
        }
    }

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length) {
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }
}
