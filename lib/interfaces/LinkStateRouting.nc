// Project 1
// CSE 160
// LinkStateRouting.nc
// Sep/28/2024
// Zaid Laffta
#include <Timer.h>
#include "../../includes/CommandMsg.h"
#include "../../includes/packet.h"
#include "../../includes/command.h"
#include "../../includes/channels.h"

interface LinkStateRouting {
    // Initializes the Link State Routing Protocol
    command error_t initialize();

    // Processes a Link State Update (LSU) packet
    command void handleLS(pack* message);

    // Fetches the routing table for debugging
    command void displayRoutingTable();
}
