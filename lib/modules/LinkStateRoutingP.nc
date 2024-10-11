#include <Timer.h>
#include "../../includes/CommandMsg.h"
#include "../../includes/packet.h"
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/sendInfo.h"


module LinkStateRoutingP {
    provides interface LinkStateRouting;
    
    uses interface Timer<TMilli> as PeriodicTimer;
    uses interface SimpleSend as Sender;
    uses interface Receive as Receive;
    uses interface NeighborDiscovery;
}

implementation {
    // Just use an array to store routing entries
    LinkStateRoutingS LinkStateRoutingS[255];
    // Keeps track of number of items in the array
    uint16_t counter = 0;

    pack myMsg;

    // Function to create a packet
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length) {
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    command void LinkStateRouting.processDiscovery() {
        dbg(GENERAL_CHANNEL, "Starting Routing\n");
        call NeighborDiscovery.processDiscovery();
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
        return 999; // Not found
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

        memcpy(TempNeighbors, tempNeighb, sizeof(struct neighborTableS) * tempTableSize);

        // Add neighbors to the list with a cost of 1
        for (uint16_t j = 0; j < tempTableSize; j++) {
            if (findEntry(TempNeighbors[j].node) == 999) {
                addToLinkStateRouting(TempNeighbors[j].node, 1, TempNeighbors[j].node);
            }
        }

        // Clear old neighbors
        for (uint32_t i = 0; i < counter; i++) {
            if (LinkStateRoutingS[i].cost == 1) {
                LinkStateRoutingS[i].cost = 999;
            }
        }

        // Update routing table with neighbors from the refreshed list
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
        for (uint32_t i = 0; i < counter; i++) {
            if (LinkStateRoutingS[i].dest == LinkStateRoutingS[i].nextHop && LinkStateRoutingS[i].nextHop != 999) {
                LinkStateRoutingS tempLinkStateRouting[1] = {LinkStateRoutingS[i]};

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
        LinkStateRoutingS tempLinkStateRouting[1];
        pack *msg = (pack *) payload;

        memcpy(tempLinkStateRouting, msg->payload, sizeof(LinkStateRoutingS[0]));
        uint32_t j = findEntry(tempLinkStateRouting[0].dest);

        // If I am neighbor, remove just in case
        if (tempLinkStateRouting[0].nextHop == TOS_NODE_ID) {
            tempLinkStateRouting[0].cost = 999;
        }

        if (j != 999) {
            if (LinkStateRoutingS[j].nextHop == msg->src) {
                // Update the cost 
                if (tempLinkStateRouting[0].cost < 999) {
                    LinkStateRoutingS[j].cost = tempLinkStateRouting[0].cost + 1;
                }
            } else if ((tempLinkStateRouting[0].cost + 1) < LinkStateRoutingS[j].cost) {
                // If my cost is lower update
                LinkStateRoutingS[j].cost = tempLinkStateRouting[0].cost + 1;
                LinkStateRoutingS[j].nextHop = msg->src;
            }
        } else {
            addToLinkStateRouting(tempLinkStateRouting[0].dest, tempLinkStateRouting[0].cost, msg->src);
        }

        return raw_msg;
    }

    command void LinkStateRouting.print() {
        dbg(GENERAL_CHANNEL, "Printing Routing Table\n");
        dbg(GENERAL_CHANNEL, "Dest\tHop\tCount\n");
                
        for (uint32_t i = 0; i < counter; i++) {
            if (LinkStateRoutingS[i].dest != 0) {
                dbg(GENERAL_CHANNEL, "%u\t\t%u\t%u\n", LinkStateRoutingS[i].dest, LinkStateRoutingS[i].nextHop, LinkStateRoutingS[i].cost);
            }
        }
    }
}
