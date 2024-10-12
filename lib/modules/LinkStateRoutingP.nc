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

    uint8_t neighborCount = 0;
    uint16_t routingTable[MAX_NEIGHBORS];

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
        // Remove neighbor from the routing table
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
}
