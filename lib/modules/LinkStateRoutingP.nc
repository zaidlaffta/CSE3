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
        uint16_t i;
        for (i = 0; i < counter; i++) {
            if (LinkStateRoutingTable[i].dest == finalDest && LinkStateRoutingTable[i].cost < 999) {
                return LinkStateRoutingTable[i].nextHop;
            }
        }
        return -1;
    }

    // Helper to find an entry in the routing table
    uint32_t findEntry(uint16_t dest) {
        uint16_t i;
        for ( i = 0; i < counter; i++) {
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

   void getNeighbors() {
    uint16_t neighborCount = call NeighborDiscovery.fetchNeighborCount();
    uint32_t* neighbors = call NeighborDiscovery.fetchNeighbors();
    
    for (uint16_t j = 0; j < neighborCount; j++) {
        uint16_t neighborID = neighbors[j];
        uint16_t ttl = call NeighborDiscovery.getNeighborTTL(neighborID);

        if (ttl > 0 && findEntry(neighborID) == 999) {
            addToLinkStateRouting(neighborID, 1, neighborID); // Add neighbor with direct link (cost = 1)
        } else if (ttl == 0) {
            // Neighbor expired; handle accordingly, such as marking the cost as high
            uint32_t index = findEntry(neighborID);
            if (index != 999) {
                LinkStateRoutingTable[index].cost = 999; // Mark as unreachable
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
void handleLS(pack* myMsg) {
    LinkStateRoutingS receivedEntry;
    memcpy(&receivedEntry, myMsg->payload, sizeof(LinkStateRoutingS));

    uint32_t entryIndex = findEntry(receivedEntry.dest);
    
    if (entryIndex != 999) { // Entry already exists
        // Update cost if the new route is shorter
        if (receivedEntry.cost + 1 < LinkStateRoutingTable[entryIndex].cost) {
            LinkStateRoutingTable[entryIndex].cost = receivedEntry.cost + 1;
            LinkStateRoutingTable[entryIndex].nextHop = myMsg->src;
            dbg(GENERAL_CHANNEL, "Updated route to %d via %d with cost %d\n", 
                receivedEntry.dest, myMsg->src, receivedEntry.cost + 1);
        }
    } else { // New entry
        addToLinkStateRouting(receivedEntry.dest, receivedEntry.cost + 1, myMsg->src);
        dbg(GENERAL_CHANNEL, "Added new route to %d via %d with cost %d\n", 
            receivedEntry.dest, myMsg->src, receivedEntry.cost + 1);
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
