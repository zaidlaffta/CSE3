#include <Timer.h>
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/protocol.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/command.h"

// LinkStateRoutingC.nc
configuration LinkStateRoutingC {
    provides interface LinkStateRouting;
    uses interface NeighborDiscovery; // Use the Neighbor Discovery interface
    uses interface Packet as Sender;   // Use a packet interface for sending
    uses interface AMSend;             // Use AMSend for sending messages
    uses interface Timer<TMilli> as RouteTimer; // Timer for periodic LSP sending
}

implementation {
    // Here we can define any additional configurations if necessary
}
