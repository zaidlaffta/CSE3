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
    uses interface Receive as Receive;
    uses interface NeighborDiscovery;
}

implementation {
    // Array to store routing entries
    LinkStateRoutingS LinkStateRoutingTable[255];
    // Keeps track of number of items in the array
    uint16_t counter = 0;

    // Function to create a packet
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length) {
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    command void LinkStateRouting.start() {
    if (payload == NULL) {
        dbg(GENERAL_CHANNEL, "Error: Payload is NULL\n");
        return;
    }

    pack* myMsg = (pack*) payload;
    
    // Check if the message is valid
    if (myMsg == NULL) {
        dbg(GENERAL_CHANNEL, "Error: myMsg is NULL after casting\n");
        return;
    }

    dbg(GENERAL_CHANNEL, "Starting Routing\n");
    
    // Call the neighbor discovery process
    call NeighborDiscovery.processDiscovery(myMsg);
    
    // Start the periodic timer
    call PeriodicTimer.startPeriodic(10000);
}

    command uint16_t LinkStateRouting.getNextHop(uint16_t finalDest) {
        uint16_t i;
        for (i = 0; i < counter; i++) {
            if (LinkStateRoutingTable[i].dest == finalDest && LinkStateRoutingTable[i].cost < 999) {
                return LinkStateRoutingTable[i].nextHop;
            }
        }
        return 999;
    }

    uint32_t findEntry(uint16_t dest) {
        for (uint16_t i = 0; i < counter; i++) {
            if (LinkStateRoutingTable[i].dest == dest) {
                return i;
            }
        }
        return 999; // Not found
    }

    void addToLinkStateRouting(uint16_t dest, uint16_t cost, uint16_t nextHop) {
        if (counter < 255 && dest != TOS_NODE_ID) {
            LinkStateRoutingTable[counter].dest = dest;
            LinkStateRoutingTable[counter].cost = cost;    
            LinkStateRoutingTable[counter].nextHop = nextHop;    
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
        for (uint16_t i = 0; i < counter; i++) {
            if (LinkStateRoutingTable[i].cost == 1) {
                LinkStateRoutingTable[i].cost = 999;
            }
        }

        // Update routing table with neighbors from the refreshed list
        for (uint16_t i = 0; i < counter; i++) {
            for (uint16_t j = 0; j < tempTableSize; j++) {
                if (TempNeighbors[j].node == LinkStateRoutingTable[i].dest) {
                    LinkStateRoutingTable[i].nextHop = LinkStateRoutingTable[i].dest;
                    LinkStateRoutingTable[i].cost = 1;        
                }
            }
        }
    }

    void sendLinkStateRouting() {
        for (uint16_t i = 0; i < counter; i++) {
            if (LinkStateRoutingTable[i].dest == LinkStateRoutingTable[i].nextHop && LinkStateRoutingTable[i].nextHop != 999) {
                LinkStateRoutingS tempLinkStateRouting[1] = {LinkStateRoutingTable[i]};

                makePack(&myMsg, TOS_NODE_ID, AM_BROADCAST_ADDR, 0, 0, PROTOCOL_PING, (uint8_t*)tempLinkStateRouting, sizeof(LinkStateRoutingTable[0]));
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

        memcpy(tempLinkStateRouting, msg->payload, sizeof(LinkStateRoutingTable[0]));
        uint32_t j = findEntry(tempLinkStateRouting[0].dest);

        // If I am neighbor, remove just in case
        if (tempLinkStateRouting[0].nextHop == TOS_NODE_ID) {
            tempLinkStateRouting[0].cost = 999;
        }

        if (j != 999) {
            if (LinkStateRoutingTable[j].nextHop == msg->src) {
                // Update the cost 
                if (tempLinkStateRouting[0].cost < 999) {
                    LinkStateRoutingTable[j].cost = tempLinkStateRouting[0].cost + 1;
                }
            } else if ((tempLinkStateRouting[0].cost + 1) < LinkStateRoutingTable[j].cost) {
                // If my cost is lower update
                LinkStateRoutingTable[j].cost = tempLinkStateRouting[0].cost + 1;
                LinkStateRoutingTable[j].nextHop = msg->src;
            }
        } else {
            addToLinkStateRouting(tempLinkStateRouting[0].dest, tempLinkStateRouting[0].cost, msg->src);
        }

        return raw_msg;
    }

    command void LinkStateRouting.print() {
        dbg(GENERAL_CHANNEL, "Printing Routing Table\n");
        dbg(GENERAL_CHANNEL, "Dest\tHop\tCount\n");
                
        for (uint16_t i = 0; i < counter; i++) {
            if (LinkStateRoutingTable[i].dest != 0) {
                dbg(GENERAL_CHANNEL, "%u\t\t%u\t%u\n", LinkStateRoutingTable[i].dest, LinkStateRoutingTable[i].nextHop, LinkStateRoutingTable[i].cost);
            }
        }
    }
}
