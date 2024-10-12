// Project 1
// CSE 160
// LinkStateRoutingP.nc
// Sep/28/2024
// Zaid Laffta

#include <Timer.h>
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/protocol.h"
module LinkStateRoutingP {
    provides interface LinkStateRouting;
    uses interface NeighborDiscovery;
    uses interface SimpleSend;
    uses interface Timer<TMilli> as LSRTimer;
}
implementation{
    uint8_t neighborCount = 0;
    uint16_t routingTable[10]; // Example max neighbors, adjust as needed

    event void Boot.booted() {
        call LSRTimer.startPeriodic(1000); // Start timer for periodic LS updates
        dbg("LinkStateRouting", "Started Link State Routing\\n");
    }

    event void LSRTimer.fired() {
        dbg("LinkStateRouting", "Periodic LSR update\\n");
        call NeighborDiscovery.ping(); // Ping neighbors to update their state
    }

    event void NeighborDiscovery.neighborAdded(uint16_t neighbor) {
        dbg("LinkStateRouting", "Neighbor added: %u\\n", neighbor);
        routingTable[neighborCount++] = neighbor;
    }

    event void NeighborDiscovery.neighborRemoved(uint16_t neighbor) {
        dbg("LinkStateRouting", "Neighbor removed: %u\\n", neighbor);
        // Logic to update routing table when neighbor is removed
        for (uint8_t i = 0; i < neighborCount; i++) {
            if (routingTable[i] == neighbor) {
                routingTable[i] = routingTable[neighborCount - 1];
                neighborCount--;
                break;
            }
        }
    }

    event void SimpleSend.sendDone(message_t* msg, error_t error) {
        if (error == SUCCESS) {
            dbg("LinkStateRouting", "Link State update sent successfully\\n");
        } else {
            dbg("LinkStateRouting", "Link State update send failed\\n");
        }
    }

   command void LinkStateRouting.printLinkStateInfo() {
    dbg("LinkStateRouting", "Printing Link State Information:\\n");
    
    for (uint8_t i = 0; i < neighborCount; i++) {
        dbg("LinkStateRouting", "Neighbor %u: %u\\n", i, routingTable[i]);
    }

    if (neighborCount == 0) {
        dbg("LinkStateRouting", "No neighbors found.\\n");
    }
}


    command void LinkStateRouting.updateRoutingTable(uint16_t neighbor) {
    bool exists = FALSE;
    
    // Check if the neighbor is already in the routing table
    for (uint8_t i = 0; i < neighborCount; i++) {
        if (routingTable[i] == neighbor) {
            exists = TRUE;
            break;
        }
    }
    
    // If the neighbor is not already in the routing table, add it
    if (!exists) {
        if (neighborCount < 10) { // Assuming a maximum of 10 neighbors
            routingTable[neighborCount++] = neighbor;
            dbg("LinkStateRouting", "Added neighbor %u to routing table\\n", neighbor);
        } else {
            dbg("LinkStateRouting", "Routing table is full. Cannot add neighbor %u\\n", neighbor);
        }
    } else {
        dbg("LinkStateRouting", "Neighbor %u already exists in the routing table\\n", neighbor);
    }
}

}
