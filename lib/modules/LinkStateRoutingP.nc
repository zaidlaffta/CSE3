#include <Timer.h>
#include "../../includes/CommandMsg.h"
#include "../../includes/packet.h"
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/sendInfo.h"

// Declare the structure for LinkStateRouting
typedef struct {
    uint16_t dest;
    uint16_t cost;
    uint16_t nextHop;
} LinkStateRoutingS;

module LinkStateRoutingP {
    provides interface LinkStateRouting;
    
    uses interface Timer<TMilli> as PeriodicTimer;
    uses interface SimpleSend as Sender;
    uses interface Receive;
    uses interface NeighborDiscovery;
}

implementation {
    LinkStateRoutingS LinkStateRoutingTable[255];
    uint16_t counter = 0;
    pack myMsg;

    // Initialize and start Link State Routing
    command void LinkStateRouting.start() {
        dbg(GENERAL_CHANNEL, "Starting Link State Routing\n");

        // Initialize Neighbor Discovery
        call NeighborDiscovery.initialize();
        
        // Start the periodic timer for neighbor updates
        call PeriodicTimer.startPeriodic(10000);
    }

    // Get the next hop for a given destination
    command uint16_t LinkStateRouting.getNextHop(uint16_t finalDest) {
        for (uint16_t i = 0; i < counter; i++) {
            if (LinkStateRoutingTable[i].dest == finalDest && LinkStateRoutingTable[i].cost < 999) {
                return LinkStateRoutingTable[i].nextHop;
            }
        }
        return 999; // Not found
    }

    // Helper to find an entry in the routing table
    uint32_t findEntry(uint16_t dest) {
        for (uint16_t i = 0; i < counter; i++) {
            if (LinkStateRoutingTable[i].dest == dest) {
                return i;
            }
        }
        return 999;
    }

    // Add an entry to the routing table
    void addToLinkStateRouting(uint16_t dest, uint16_t cost, uint16_t nextHop) {
        if (counter < 255 && dest != TOS_NODE_ID) {
            LinkStateRoutingTable[counter].dest = dest;
            LinkStateRoutingTable[counter].cost = cost;
            LinkStateRoutingTable[counter].nextHop = nextHop;
            counter++;
        }
    }

    // Update routing table from neighbors
    void getNeighbors() {
        uint16_t tempTableSize = call NeighborDiscovery.getNeighborListSize();
        struct neighborTableS TempNeighbors[255];
        void* tempNeighb = call NeighborDiscovery.getNeighborList();
        memcpy(TempNeighbors, tempNeighb, sizeof(struct neighborTableS) * tempTableSize);

        for (uint16_t j = 0; j < tempTableSize; j++) {
            if (findEntry(TempNeighbors[j].node) == 999) {
                addToLinkStateRouting(TempNeighbors[j].node, 1, TempNeighbors[j].node);
            }
        }

        for (uint16_t i = 0; i < counter; i++) {
            if (LinkStateRoutingTable[i].cost == 1) {
                LinkStateRoutingTable[i].cost = 999;
            }
        }

        for (uint16_t i = 0; i < counter; i++) {
            for (uint16_t j = 0; j < tempTableSize; j++) {
                if (TempNeighbors[j].node == LinkStateRoutingTable[i].dest) {
                    LinkStateRoutingTable[i].nextHop = LinkStateRoutingTable[i].dest;
                    LinkStateRoutingTable[i].cost = 1;
                }
            }
        }
    }

    // Periodic updates
    event void PeriodicTimer.fired() {
        getNeighbors();
        sendLinkStateRouting();
    }

    // Send the routing information
    void sendLinkStateRouting() {
        for (uint16_t i = 0; i < counter; i++) {
            if (LinkStateRoutingTable[i].dest == LinkStateRoutingTable[i].nextHop && LinkStateRoutingTable[i].nextHop != 999) {
                LinkStateRoutingS tempLinkStateRouting[1] = {LinkStateRoutingTable[i]};
                makePack(&myMsg, TOS_NODE_ID, AM_BROADCAST_ADDR, 0, PROTOCOL_PING, 0, (uint8_t*)tempLinkStateRouting, sizeof(LinkStateRoutingTable[0]));
                call Sender.send(&myMsg, AM_BROADCAST_ADDR);
            }
        }
    }

    // Handle incoming messages
    event message_t* Receive.receive(message_t* raw_msg, void* payload, uint8_t len) {
        pack *msg = (pack *) payload;
        LinkStateRoutingS tempLinkStateRouting[1];

        if (len == sizeof(pack) && msg->protocol == PROTOCOL_LS) {
            memcpy(tempLinkStateRouting, msg->payload, sizeof(LinkStateRoutingTable[0]));
            uint32_t j = findEntry(tempLinkStateRouting[0].dest);

            if (tempLinkStateRouting[0].nextHop == TOS_NODE_ID) {
                tempLinkStateRouting[0].cost = 999;
            }

            if (j != 999) {
                if (LinkStateRoutingTable[j].nextHop == msg->src) {
                    if (tempLinkStateRouting[0].cost < 999) {
                        LinkStateRoutingTable[j].cost = tempLinkStateRouting[0].cost + 1;
                    }
                } else if ((tempLinkStateRouting[0].cost + 1) < LinkStateRoutingTable[j].cost) {
                    LinkStateRoutingTable[j].cost = tempLinkStateRouting[0].cost + 1;
                    LinkStateRoutingTable[j].nextHop = msg->src;
                }
            } else {
                addToLinkStateRouting(tempLinkStateRouting[0].dest, tempLinkStateRouting[0].cost, msg->src);
            }
        }
        return raw_msg;
    }

    // Print routing table
    command void LinkStateRouting.print() {
        dbg(GENERAL_CHANNEL, "Printing Routing Table\n");
        dbg(GENERAL_CHANNEL, "Dest\tHop\tCost\n");

        for (uint16_t i = 0; i < counter; i++) {
            if (LinkStateRoutingTable[i].dest != 0) {
                dbg(GENERAL_CHANNEL, "%u\t%u\t%u\n", LinkStateRoutingTable[i].dest, LinkStateRoutingTable[i].nextHop, LinkStateRoutingTable[i].cost);
            }
        }
    }
}
