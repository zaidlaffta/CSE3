#include "../../includes/packet.h"

// LinkStateRouting.nc
interface LinkStateRouting {
    command void start();             // Start the routing protocol
    command void sendLSP();          // Send a Link-State Packet (LSP)
    event void lspReceived(LSPPacket* lsp); // Event triggered when an LSP is received
}

