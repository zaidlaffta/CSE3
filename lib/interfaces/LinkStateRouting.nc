// Project 1
// CSE 160
// LinkStateRouting.nc
// Sep/28/2024
// Zaid Laffta

interface LinkStateRouting {
    // Initializes the Link State Routing Protocol
    command error_t initialize();

    // Processes a Link State Update (LSU) packet
    command void handleLS(pack* message);

    // Fetches the routing table for debugging
    command void displayRoutingTable();
}
