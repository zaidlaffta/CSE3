#include "../../includes/packet.h"

// LinkStateRouting.nc
interface LinkStateRouting {
    command void start();             // Start the routing protocol
    command void sendLSP();          // Send a Link-State Packet (LSP)
    event void lspReceived(LSPPacket* lsp); // Event triggered when an LSP is received
}

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
