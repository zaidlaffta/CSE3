
#include <Timer.h>
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/protocol.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/command.h"

// LinkStateRoutingP.nc
module LinkStateRoutingP {
    provides interface LinkStateRouting;
    uses interface NeighborDiscovery;
    uses interface Packet as Sender;
    uses interface AMSend;
    uses interface Timer<TMilli> as RouteTimer;

    uint16_t sequenceNum = 0; // Sequence number for LSPs

// Define the structure for a neighbor information
typedef struct {
    uint32_t neighbor;  // ID of the neighbor
    uint8_t cost;       // Cost to reach the neighbor
} NeighborInfo;

// Define the structure for the Link-State Packet (LSP)
typedef struct {
    uint16_t sequenceNum;  // Sequence number of the LSP
    uint8_t ttl;           // Time-to-live for the LSP
    uint8_t numNeighbors;  // Number of neighbors in the LSP
    NeighborInfo neighbors[10]; // Array of neighbor information (max 10)
} LSPPacket;


    // Define the routing table and neighbors list
    typedef struct {
        uint32_t neighbor;  // Neighbor ID
        uint16_t cost;      // Cost to reach the neighbor
    } RoutingTableEntry;

    RoutingTableEntry routingTable[20]; // Array for routing table (size as needed)
    uint8_t routingTableSize = 0; // Size of the routing table

    event void Boot.booted() {
        call RouteTimer.startPeriodic(60000); // Start timer to send LSP every 60 seconds
    }

    command void LinkStateRouting.start() {
        call NeighborDiscovery.start(); // Start neighbor discovery
    }

    command void LinkStateRouting.sendLSP() {
        uint32_t* neighbors = call NeighborDiscovery.fetchNeighbors(); // Fetch neighbors
        uint16_t numNeighbors = call NeighborDiscovery.fetchNeighborCount(); // Count neighbors
        LSPPacket lsp; // Create an LSP packet

        lsp.sequenceNum = sequenceNum++; // Increment sequence number
        lsp.ttl = 10; // Set TTL
        lsp.numNeighbors = numNeighbors; // Set number of neighbors

        for (uint8_t i = 0; i < numNeighbors && i < 10; i++) {
            lsp.neighbors[i].neighbor = neighbors[i]; // Set neighbor ID
            lsp.neighbors[i].cost = 1; // Default cost to 1
        }

        message_t* msg = call Sender.getPayload(NULL, sizeof(LSPPacket)); // Get payload for sending
        memcpy(msg->data, &lsp, sizeof(LSPPacket)); // Copy LSP to message

        if (call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(LSPPacket)) != SUCCESS) {
            dbg("Routing", "Failed to send LSP packet.\n"); // Debug message
        }
    }

    event message_t* AMSend.receive(message_t* msg, void* payload, uint8_t len) {
        if (len != sizeof(LSPPacket)) return msg; // Check length of the message
        LSPPacket* receivedLSP = (LSPPacket*) payload; // Cast payload to LSPPacket
        
        if (isNewerLSP(receivedLSP)) {
            updateRoutingTable(receivedLSP); // Update routing table
            signal LinkStateRouting.lspReceived(receivedLSP); // Signal LSP received event
            floodLSP(receivedLSP); // Flood LSP to neighbors
        }

        return msg;
    }

    task void updateRoutingTable(LSPPacket* lsp) {
        // Logic to update routing table with received LSP information
        // Implement the necessary logic here
    }

    task void floodLSP(LSPPacket* lsp) {
        // Logic to flood LSP to neighbors with reduced TTL
        if (lsp->ttl > 0) {
            lsp->ttl--; // Decrease TTL
            // Send the LSP to neighbors again
            // Implement sending logic here
        }
    }

    bool isNewerLSP(LSPPacket* lsp) {
        // Logic to determine if the LSP is newer than the one in the routing table
        // Implement the necessary logic here
    }
}
