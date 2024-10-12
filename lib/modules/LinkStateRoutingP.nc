// Project 1
// CSE 160
// LinkStateRoutingP.nc
// Sep/28/2024
// Zaid Laffta

#include <Timer.h>
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/protocol.h"

#define MAX_NODES 20 // Adjust based on the network size
#define LINK_STATE_TTL 30

module LinkStateRoutingP {
    provides interface LinkStateRouting;
    uses interface NeighborDiscovery;
    uses interface Timer<TMilli> as LSTimer;
    uses interface SimpleSend as Broadcaster;
}

implementation {
    typedef struct {
        uint16_t nodeID;
        uint16_t cost;
    } LinkStateEntry;

    typedef struct {
        uint16_t nodeID;
        LinkStateEntry neighbors[MAX_NODES];
        uint8_t neighborCount;
    } RoutingTableEntry;


    event void LSTimer.fired() {
    uint8_t payload[MAX_NODES * sizeof(LinkStateEntry)];
    uint8_t len = 0;

    // Collect neighbor information and fill payload (update as per your neighbor structure)
    // Example: payload logic

    makeLS(&LSPacket, TOS_NODE_ID, LINK_STATE_TTL, payload, len);
    call Broadcaster.send(LSPacket, AM_BROADCAST_ADDR);
    dbg(GENERAL_CHANNEL, "Link State Update broadcasted\n");
}
    // Routing Table and Timer
    RoutingTableEntry routingTable[MAX_NODES];
    uint8_t tableSize = 0;
    pack LSPacket;

    // Helper function to create Link State Update packets
    void makeLS(pack *pkt, uint16_t src, uint16_t ttl, uint8_t* payload, uint8_t len);

    // Initialize Link State Routing
    command error_t LinkStateRouting.initialize() {
        call LSTimer.startPeriodic(1000); // Every second
        dbg(GENERAL_CHANNEL, "Link State Routing Initialized\n");
        return SUCCESS;
    }

    command void LinkStateRouting.handleLS(pack* message) {
    uint16_t src = message->src;
    dbg(GENERAL_CHANNEL, "Handling Link State Update from Node %d\n", src);

    bool exists = FALSE;
    uint8_t i;

    // Check if the source node is already in the routing table
    for (i = 0; i < tableSize; i++) {
        if (routingTable[i].nodeID == src) {
            exists = TRUE;
            break;
        }
    }

    // If the node doesn't exist, add it to the table
    if (!exists && tableSize < MAX_NODES) {
        routingTable[tableSize].nodeID = src;
        routingTable[tableSize].neighborCount = 0; // Adjust as necessary
        tableSize++;
    }

    // Additional logic for updating routing table entries based on the packet payload
    // (Extract neighbors from payload and update accordingly)
}

    command void LinkStateRouting.displayRoutingTable() {
    dbg(GENERAL_CHANNEL, "Displaying Routing Table:\n");
    uint8_t i, j;
    for (i = 0; i < tableSize; i++) {
        dbg(GENERAL_CHANNEL, "Node %d:\n", routingTable[i].nodeID);
        for (j = 0; j < routingTable[i].neighborCount; j++) {
            dbg(GENERAL_CHANNEL, "  Neighbor %d, Cost %d\n",
                routingTable[i].neighbors[j].nodeID,
                routingTable[i].neighbors[j].cost);
        }
    }
}


    // Periodically broadcast Link State Updates
    event void LSTimer.fired() {
        uint8_t payload[MAX_NODES * sizeof(LinkStateEntry)];
        uint8_t len = 0;

        // Collect neighbor information and fill payload
        for (uint8_t i = 0; i < call NeighborDiscovery.fetchNeighborCount(); i++) {
            // Example: assuming each entry has nodeID and cost
            // Adjust payload construction as per your LinkStateEntry structure
        }

        makeLS(&LSPacket, TOS_NODE_ID, LINK_STATE_TTL, payload, len);
        call Broadcaster.send(LSPacket, AM_BROADCAST_ADDR);
        dbg(GENERAL_CHANNEL, "Link State Update broadcasted\n");
    }

    // Helper function to prepare Link State packets
    void makeLS(pack *pkt, uint16_t src, uint16_t ttl, uint8_t* payload, uint8_t len) {
        pkt->src = src;
        pkt->dest = 0;
        pkt->TTL = ttl;
        pkt->protocol = PROTOCOL_LS;
        memcpy(pkt->payload, payload, len);
    }
}
